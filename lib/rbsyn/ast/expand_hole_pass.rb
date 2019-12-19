class ExpandHolePass < ::AST::Processor
  include AST
  include TypeOperations

  attr_reader :expand_map

  def initialize(ctx)
    @expand_map = []
    @ctx = ctx
  end

  def on_hole(node)
    depth = node.children[0]
    max_depth = node.children[1]
    is_pc = node.children[2]
    expanded = []

    if depth == 0
      # synthesize boolean constants
      if node.ttype <= RDL::Globals.types[:bool] && !is_pc
        expanded.concat bool_const
      end

      if node.ttype.is_a?(RDL::Type::SingletonType) && node.ttype.val.is_a?(Symbol)
        expanded.concat symbols([node.ttype])
      end

      if node.ttype.is_a?(RDL::Type::UnionType) &&
        node.ttype.types.all? { |t| t.is_a?(RDL::Type::SingletonType) && t.val.is_a?(Symbol) }
        expanded.concat symbols(node.ttype.types)
      end

      # synthesize variables in the environment
      expanded.concat lvar(node.ttype)

      if node.ttype.is_a? RDL::Type::FiniteHashType
        expanded.concat finite_hash(node.ttype)
      end
    else
      # synthesize function calls
      r = Reachability.new(@ctx.tenv)
      paths = r.paths_to_type(node.ttype, depth)
      expanded.concat paths.map { |path| fn_call(path) }
    end

    if depth + 1 <= max_depth
      # synthesize a hole with higher depth
      expanded << s(node.ttype, :hole, depth + 1, max_depth, false)
    end

    @expand_map << expanded.size
    s(node.ttype, :filled_hole, *expanded)
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end

  private
  def bool_const
    [s(RDL::Globals.types[:bool], :true),
    s(RDL::Globals.types[:bool], :false)]
  end

  def symbols(types)
    # assume types are singleton types are symbols
    types.map { |t| s(t, :sym, t.val) }
  end

  def lvar(type)
    @ctx.tenv.select { |k, v| v <= type }
      .map { |k, v| TypedNode.new(type, :lvar, k) }
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
        # allowing only lvars now
        hole_args = targs.map { |targ| s(targ, :hole, 0, 0, false) }
        if accum.nil?
          accum = s(tret, :send, s(trecv, :hole, 0, 0, false),
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
          s(v.type, :hole, 0, 0, false))
      }
      # puts "===="
      # puts keyvals
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
