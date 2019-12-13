class Context
  attr_accessor :fn_call_depth, :components, :preconds, :args, :postconds,
    :reset_func, :functype, :tenv

  def initialize
    @fn_call_depth = 0
    @components = []
    @preconds = []
    @args = []
    @postconds = []
    @tenv = {}
    @reset_func = nil
    @functype = nil
  end

  def add_example(precond, arg, postcond)
    @preconds << precond
    @args << arg
    @postconds << postcond
  end

  def load_tenv!
    @functype.args.each_with_index { |type, i|
      @tenv["arg#{i}".to_sym] = type
    }
    @components.each { |component|
      @tenv[component] = RDL::Type::SingletonType.new(component)
    }
  end
end
