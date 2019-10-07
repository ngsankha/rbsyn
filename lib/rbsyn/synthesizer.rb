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
  include SynHelper

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

  def generate(depth, tenv, components, tout)
    # TODO: better way to handle errors when max depth is reached?
    return [] unless depth <= @max_depth

    components.map { |component|
      syn(component, tenv, tout, CONTRAVARIANT)[0]
    }.flatten
  end
end
