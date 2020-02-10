class Context
  attr_accessor :max_prog_size, :components, :preconds, :args, :postconds,
    :reset_func, :functype, :tenv, :max_hash_size, :max_arg_length, :max_hash_depth

  def initialize
    @max_prog_size = 0
    @components = []
    @preconds = []
    @args = []
    @postconds = []
    @tenv = {}
    @reset_func = nil
    @functype = nil
    @max_hash_size = 2
    @max_arg_length = 1
    @max_hash_depth = 1
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
