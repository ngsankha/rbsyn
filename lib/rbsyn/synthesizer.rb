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

    @max_depth.times { |depth|
      generate(depth + 1, tenv, initial_components, tout).each { |prog|
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

  def guess_initial_components(tout)
    always = [:send, :lvar]

    return [:true, :false, *always] if tout <= RDL::Globals.types[:bool]
    return always
  end

  def generate(depth, tenv, components, tout)
    r = Reachability.new(tenv)
    paths = r.paths_to_type(tout, depth)

    components.map { |component|
      # syn returns 2 values. The first one is the set of concrete programs,
      # and the second one is the set of programs with holes.
      # The second one is always empty at the moment as we don't actually make
      # use of holes at the moment
      syn(component, tenv, tout, CONTRAVARIANT, { reach_set: paths })[0]
    }.flatten
  end
end
