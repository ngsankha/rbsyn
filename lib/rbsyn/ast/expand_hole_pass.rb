class ExpandHolePass < ::AST::Processor
  include AST
  include TypeOperations

  attr_reader :expand_map
  attr_writer :effect_methds

  def initialize(ctx, env)
    @expand_map = []
    @visited_envrefs = Set.new
    @ctx = ctx
    raise RuntimeError, "expected LocalEnvironment" unless env.is_a? LocalEnvironment
    @env = env
  end

  def on_envref(node)
    ref = node.children[0]
    @visited_envrefs.add(ref)
    info = @env.get_expr(ref)
    info[:expr] = process(info[:expr])
    node
  end

  def on_hole(node)
    depth = node.children[0]
    @params = node.children[1]
    @no_bool_consts = !@params.fetch(:bool_consts, true)
    @curr_hash_depth = @params.fetch(:hash_depth, 0)
    @method_arg = @params.fetch(:method_arg, false)
    @effect = @params.fetch(:effect, false)
    @limit_depth = @params.fetch(:limit_depth, false)
    @variance = @params.fetch(:variance, COVARIANT)
    @recv = @params.fetch(:recv, false)
    expanded = []

    if depth == 0
      # nil constant
      if @ctx.enable_nil# && !@recv
        expanded << nil_const
      end

      # boolean constants
      if node.ttype <= RDL::Globals.types[:bool] && !@no_bool_consts
        expanded.concat bool_const
      end

      # and of 2 boolean expressions
      if node.ttype <= RDL::Globals.types[:bool] && @no_bool_consts && @ctx.enable_and
        expanded << s(RDL::Globals.types[:bool], :and,
          s(RDL::Globals.types[:bool], :hole, 0, { bool_consts: false }),
          s(RDL::Globals.types[:bool], :hole, 0, { bool_consts: false }))
      end

      # integer constants
      if node.ttype <= RDL::Globals.types[:integer] && @ctx.enable_constants
        expanded.concat int_const
      end

      # string constants
      if node.ttype <= RDL::Globals.types[:string] && @ctx.enable_constants
        expanded.concat string_const
      end

      # symbols
      if node.ttype.is_a?(RDL::Type::SingletonType) && node.ttype.val.is_a?(Symbol)
        expanded.concat symbols([node.ttype])
      end

      # union of symbols
      if node.ttype.is_a?(RDL::Type::UnionType) &&
        node.ttype.types.all? { |t| t.is_a?(RDL::Type::SingletonType) && t.val.is_a?(Symbol) }
        expanded.concat symbols(node.ttype.types)
      end

      # real program variables in the environment
      expanded.concat lvar(node.ttype)

      # hashes
      # receivers are not hashes for now
      if node.ttype.is_a?(RDL::Type::FiniteHashType) && @curr_hash_depth < @ctx.max_hash_depth && !@recv
        expanded.concat finite_hash(node.ttype)
      end

      # possibly reusable subexpressions
      expanded.concat envref(node.ttype)
    elsif depth > 0 && !@effect
      # synthesize function calls
      r = Reachability.new(@ctx.tenv)
      paths = r.paths_to_type(node.ttype, depth, @variance)
      expanded.concat paths.map { |path| fn_call(path) }
    elsif depth == 1 && @effect
      expanded.concat effects
    else
      raise RuntimeError, "unexpected"
    end

    # synthesize a hole with higher depth
    # TODO: we don't do this if we are synthesizing for effects, will do after
    # effect reachability graph is implemented
    expanded << s(node.ttype, :hole, depth + 1, {hash_depth: @curr_hash_depth, method_arg: @method_arg, variance: @variance}) unless (@effect || @limit_depth)

    @expand_map << expanded.size
    s(node.ttype, :filled_hole, *expanded, {method_arg: @method_arg})
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end

  private
  def effects
    arg_types = @ctx.functype.args.map { |t|
      if t.is_a? RDL::Type::UnionType
        t.types
      else
        t
      end
    }.flatten
    env_types = @env.info.values.map { |v|
      if v[:expr].ttype.is_a? RDL::Type::UnionType
        v[:expr].ttype.types
      else
        v[:expr].ttype
      end
    }.flatten

    types = Set[*(arg_types + env_types +
      @ctx.components.map { |c| RDL::Type::SingletonType.new(c) })]
    exprs = []

    @effect_methds.each { |klass, methd|
      types.each { |type|
        case type
        when RDL::Globals.types[:bool], RDL::Globals.types[:bot]
          # ignore
          next
        when RDL::Type::SingletonType
          next if RDL::Util.has_singleton_marker(klass).nil?
          klass_qual = RDL::Util.to_class(RDL::Util.remove_singleton_marker(klass))
          recv_qual = RDL::Util.to_class(type.val)
          if recv_qual.ancestors.include? klass_qual
            trecv = type
            path = CallChain.new([trecv, methd, RDL::Globals.types[:bot]], @ctx.tenv)
            exprs << fn_call(path)
          end
        when RDL::Type::NominalType
          klass_qual = RDL::Util.to_class(klass)
          recv_qual = RDL::Util.to_class(type.name)
          if recv_qual.ancestors.include? klass_qual
            trecv = type
            # the %top type here doesn't matter
            path = CallChain.new([trecv, methd, RDL::Globals.types[:bot]], @ctx.tenv)
            exprs << fn_call(path)
          end
        when RDL::Type::GenericType
          # ignore
          next
        when RDL::Type::FiniteHashType
          if klass == Hash
            trecv = type
            path = CallChain.new([trecv, methd, RDL::Globals.types[:bot]], @ctx.tenv)
            exprs << fn_call(path)
          end
        when RDL::Type::DynamicType
          path = CallChain.new([type, methd, RDL::Globals.types[:bot]], @ctx.tenv)
          exprs << fn_call(path)
        else
          raise RuntimeError, "unhandled type #{type}"
        end
      }
    }

    exprs
  end

  def nil_const
    s(RDL::Globals.types[:nil], :nil)
  end

  def bool_const
    [s(RDL::Globals.types[:bool], :true),
    s(RDL::Globals.types[:bool], :false)]
  end

  def int_const
    @ctx.constants[:integer].map { |i| s(RDL::Globals.types[:integer], :int, i) }
  end

  def string_const
    @ctx.constants[:string].map { |i| s(RDL::Globals.types[:string], :str, i) }
  end

  def symbols(types)
    # assume types are singleton types are symbols
    types.map { |t| s(t, :sym, t.val) }
  end

  def lvar(type)
    @ctx.tenv.select { |k, v| v <= type }
      .map { |k, v| s(v, :lvar, k) }
  end

  def envref(type)
    @env.exprs_with_type(type)
      .reject { |ref| @visited_envrefs.include? ref }
      .map { |ref| s(type, :envref, ref) }
  end

  def fn_call(path)
    tokens = path.path.to_enum
    accum = nil
    loop {
      begin
        trecv = tokens.next
        mth = tokens.next
        mthds = methods_of(trecv)
        info = mthds[mth]
        tmeth = info[:type]
        targs = compute_targs(trecv, tmeth)
        tret = compute_tout(trecv, tmeth, targs)
        hole_args = targs.map { |targ| s(targ, :hole, 0, {hash_depth: @curr_hash_depth, method_arg: true}) }
        if accum.nil?
          accum = s(tret, :send, s(trecv, :hole, 0, {hash_depth: @curr_hash_depth, limit_depth: true, recv: true}),
            mth, *hole_args)
        else
          raise RuntimeError, "expected type" unless accum.ttype <= trecv
          accum = s(tret, :send, accum, mth, *hole_args)
        end
      rescue StopIteration
        break
      end
    }
    accum
  end

  def finite_hash(type)
    # TODO: some hashes can have mandatory keys too
    type.elts.each { |k, t| raise RuntimeError, "expect everything to be optional in a hash" unless t.is_a? RDL::Type::OptionalType }
    possible_types = (1..@ctx.max_hash_size).map { |size|
      hash_combinations(type, size)
    }.flatten
    possible_types.map { |thash|
      keyvals = thash.elts.map { |k, v|
        s(RDL::Globals.types[:top], :pair,
          s(RDL::Globals.types[:top], :sym, k),
          s(v.type, :hole, 0, {hash_depth: @curr_hash_depth + 1}))
      }
      s(thash, :hash, *keyvals)
    }
  end

  def hash_combinations(thash, size)
    choices = thash.elts.to_a.combination(size).map { |arr| RDL::Type::FiniteHashType.new(Hash[arr], nil) }
    choices.map { |choice|
      choice = choice.elts
      rest = choice.reject { |k, v| v.is_a? RDL::Type::FiniteHashType }
      hashes = choice.select { |k, v| v.is_a? RDL::Type::FiniteHashType }
      hashes_arr = []
      hashes.each { |k, v|
        hash_choices = []
        hash_size = v.elts.size
        hash_size.times { |hs|
          hs += 1
          hash_choices.push(*hash_combinations(v, hs))
        }
        hash_choices.map! { |h| [k, h] }
        hashes_arr << hash_choices
      }

      if hashes_arr.empty?
        [RDL::Type::FiniteHashType.new(rest, nil)]
      else
        [rest.to_a].product(*hashes_arr).map { |h|
          first = h.shift
          h = [*h, *first]
          RDL::Type::FiniteHashType.new(Hash[h], nil)
        }
      end
    }.flatten(1)
  end
end
