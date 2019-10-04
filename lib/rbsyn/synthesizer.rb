COVARIANT = :+
CONTRAVARIANT = :-

class TypedAST
  attr_reader :type, :expr

  def initialize(type, expr)
    @type = type
    @expr = expr
  end
end

class Synthesizer
  include AST

  def initialize(max_depth: 5, components: [])
    @test_setup = []
    @envs = []
    @outputs = []
    @max_depth = max_depth
    @components = components
  end

  def add_example(input, output, &blk)
    DBUtils.reset
    yield if block_given?
    @test_setup << blk
    @envs << env_from_args(input)
    @outputs << output
    DBUtils.reset
  end

  def run
    tenv = TypeEnvironment.new
    @envs.map(&:to_type_env).each { |t| tenv = tenv.merge(t) }
    tenv = load_components(tenv)

    toutenv = TypeEnvironment.new
    @outenv = @outputs.map { |o|
      env = ValEnvironment.new
      env[:out] = o
      env.to_type_env
    }.each { |t| toutenv = toutenv.merge(t) }

    tout = toutenv[:out].type
    initial_components = guess_initial_components(tout)

    generate(0, tenv, initial_components, tout).each { |prog|
      prog = prog.expr
      begin
        outputs = @test_setup.zip(@envs).map { |setup, env|
          eval_ast(prog, env) { setup.call unless setup.nil? } rescue next
        }
        return prog if outputs == @outputs
      rescue Exception => e
        next
      end
    }
    raise RuntimeError, "No candidates found"
  end

  private

  def env_from_args(input)
    env = ValEnvironment.new
    input.each_with_index { |v, i|
      env["arg#{i}".to_sym] = v
    }
    env
  end

  def load_components(env)
    raise RuntimeError unless env.is_a? TypeEnvironment
    @components.each { |c|
      env[c.to_s.to_sym] = RDL::Type::SingletonType.new(c)
    }
    env
  end

  def cls_mths_with_type_defns(cls)
    cls = RDL::Util.to_class(cls.to_s)
    parents = cls.ancestors
    parents = parents[0...parents.index(Object)]
    Hash[*parents.map { |parent|
      klass = RDL::Util.add_singleton_marker(parent.to_s)
      RDL::Globals.info.info[klass]
    }.reject(&:nil?).collect { |h| h.to_a }.flatten]
  end

  def compute_targs(trec, tmeth)
    # TODO: we use only the first definition, ignoring overloaded method definitions
    type = tmeth[0]
    targs = type.args
    targs.map { |targ|
      case targ
      when RDL::Type::ComputedType
        bind = Class.new.class_eval { binding }
        bind.local_variable_set(:trec, trec)
        targ.compute(bind)
      else
        raise RuntimeError, "unhandled type #{targ}"
      end
    }
  end

  def compute_tout(trec, tmeth, targs)
    # TODO: we use only the first definition, ignoring overloaded method definitions
    type = tmeth[0]
    tret = type.ret
    case tret
    when RDL::Type::ComputedType
      bind = Class.new.class_eval { binding }
      bind.local_variable_set(:trec, trec)
      bind.local_variable_set(:targs, targs)
      tret.compute(bind)
    else
      tret
    end
  end

  def guess_initial_components(tout)
    always = [:send, :lvar]

    return [:true, :false, *always] if tout <= RDL::Globals.types[:bool]
    return always
  end

  def syn_bool(component, tenv, tout, variance)
    type = RDL::Globals.types[:bool]
    raise RuntimeError, "type mismatch for boolean" unless tout <= type
    return [TypedAST.new(RDL::Globals.types[component], s(component))]
  end

  def syn_const(component, tenv, tout, variance)
    type = RDL::Type::NominalType.new(Class)
    raise RuntimeError, "type mismatch for const" unless tout <= type
    consts = tenv.bindings_with_type(type).select { |k, v| v.type <= tout }
    return consts.map { |k, v|
      TypedAST.new(RDL::Type::SingletonType.new(RDL::Util.to_class(k)), s(:const, nil, k))
    }
  end

  def syn_send(component, tenv, tout, variance)
    consts = syn_const(:const, tenv, RDL::Type::NominalType.new(Class), COVARIANT)
    guesses = []

    consts.map { |recv|
      recv_type = recv.type
      recv_cls = recv.expr.children[1]
      class_meths = cls_mths_with_type_defns(recv_cls)
      class_meths.each { |mth, info|
        targs = compute_targs(recv_type, info[:type])
        # TODO: we only handle the first argument now
        targ = targs[0]
        case targ
        when RDL::Type::FiniteHashType
          guesses.concat syn_hash(:hash, tenv, targ, COVARIANT).map { |h|
            TypedAST.new(compute_tout(recv_type, info[:type], targs), s(:send, recv.expr, mth, h.expr))
          }
        when RDL::Type::SingletonType
          case targ.val
          when Symbol
            guesses << TypedAST.new(compute_tout(recv_type, info[:type], targs), s(:send, recv.expr, mth, s(:sym, targ.val)))
          else
            raise RuntimeError, "Don't know how to emit singletons apart from symbol"
          end
        else
          raise RuntimeError, "Don't know how to handle #{targ}"
        end
      }
    }
    return guesses
  end

  def syn_hash(component, tenv, tout, variance)
    raise RuntimeError unless tout.is_a? RDL::Type::FiniteHashType

    guesses = []
    # TODO: generate hashes with multiple keys
    # TODO: some hashes can have mandatory keys too
    tout.elts.each { |k, t|
      raise RuntimeError, "expect everything to be optional in a hash" unless t.is_a? RDL::Type::OptionalType
      t = t.type
      guesses.concat syn_lvar(:lvar, tenv, t, COVARIANT).map { |v|
        TypedAST.new(RDL::Type::FiniteHashType.new({k: v.type}, nil), s(:hash, s(:pair, s(:sym, k), v.expr)))
      }
    }

    return guesses
  end

  def syn_lvar(component, tenv, tout, variance)
    if variance == CONTRAVARIANT
      vars = tenv.bindings_with_supertype(tout)
    elsif variance == COVARIANT
      vars = tenv.bindings_with_type(tout)
    end
    return vars.map { |var, binding|
      TypedAST.new(RDL::Type::NominalType.new(binding.type), s(:lvar, var))
    }
  end

  def generate(depth, tenv, components, tout)
    # TODO: pass flags for covariant vs contravariant
    # TODO: better way to handle errors when max depth is reached?
    return [] unless depth <= @max_depth

    components.map { |component|
      case component
      when :true, :false
        syn_bool(component, tenv, tout, CONTRAVARIANT)
      when :const
        syn_const(component, tenv, tout, CONTRAVARIANT)
      when :send
        syn_send(component, tenv, tout, CONTRAVARIANT)
      when :hash
        syn_hash(component, tenv, tout, CONTRAVARIANT)
      when :lvar
        syn_lvar(component, tenv, tout, CONTRAVARIANT)
      else
        raise RuntimeError, "unknown ast node"
      end
    }.flatten
  end
end
