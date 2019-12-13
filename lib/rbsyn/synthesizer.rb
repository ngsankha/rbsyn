COVARIANT = :+
CONTRAVARIANT = :-

class Synthesizer
  include AST
  include SynHelper

  def initialize(ctx)
    @ctx = ctx
  end

  def run
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
