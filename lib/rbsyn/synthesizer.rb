COVARIANT = :+
CONTRAVARIANT = :-

class TypedAST
  attr_reader :type, :expr

  def initialize(type, expr)
    @type = type
    @expr = expr
  end

  def to_s
    "#{Unparser.unparse(@expr)} : #{@type}"
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
    @envs.zip(@outputs, @test_setup).each { |env, output, setup|
      prog = synthesize(@max_depth, [env], [output], [setup])
      branch = synthesize(@max_depth, [env], [true], [setup], [:true, :false])
      puts prog
      puts "====="
      puts branch
      puts "====="
    }
  end

  private

  def synthesize(max_depth, envs, outputs, setups, forbidden_components=[])
    tenv = TypeEnvironment.new
    envs.map(&:to_type_env).each { |t| tenv = tenv.merge(t) }
    tenv = load_components(tenv)

    toutenv = TypeEnvironment.new
    outputs.map { |o|
      env = ValEnvironment.new
      env[:out] = o
      env.to_type_env
    }.each { |t| toutenv = toutenv.merge(t) }
    tout = toutenv[:out].type
    initial_components = guess_initial_components(tout) - forbidden_components

    (max_depth + 1).times { |depth|
      progs = generate(depth, tenv, initial_components, tout).select { |prog|
        prog = prog.expr
        begin
          run_outputs = setups.zip(envs).map { |setup, env|
            eval_ast(prog, env) { setup.call unless setup.nil? } rescue next
          }
          run_outputs == outputs
        rescue Exception => e
          next
        end
      }
      return progs if progs.size > 0
    }
    raise RuntimeError, "No candidates found"
  end

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
    if depth == 0
      components = components - [:send]
      components.map { |component|
        # syn returns 2 values. The first one is the set of concrete programs,
        # and the second one is the set of programs with holes.
        # The second one is always empty at the moment as we don't actually make
        # use of holes at the moment
        syn(component, tenv, tout, CONTRAVARIANT)[0]
      }.flatten
    else
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
end
