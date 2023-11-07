require 'logger'

class Context
  attr_accessor :max_prog_size, :components, :preconds, :postconds, :mth_name,
    :reset_func, :functype, :tenv, :max_hash_size, :max_arg_length, :max_hash_depth,
    :curr_binding, :constants, :enable_and, :enable_constants, :enable_nil, :seed_expr

  attr_reader :logger

  def initialize
    @max_prog_size = 0
    @components = []
    @preconds = []
    @postconds = []
    @tenv = {}
    @reset_func = nil
    @functype = nil
    @mth_name = ""
    @max_hash_size = 1
    @max_arg_length = 1
    @max_hash_depth = 1
    @next_ref = 0
    @ref_map = {}
    @curr_binding = nil
    @constants = {
      string: [''],
      integer: [0, 1, 3]
    }
    @enable_and = false
    @enable_constants = false
    @enable_nil = false

    @logger = Logger.new(STDOUT)
    logger.level = case ENV['LOG']
    when 'DEBUG'
      Logger::DEBUG
    else
      Logger::WARN
    end
  end

  def add_example(precond, postcond)
    @preconds << precond
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

  def to_ctx_ref(ref)
    if @ref_map.key? ref
      @ref_map[ref]
    else
      old_ref = @next_ref
      @next_ref += 1
      @ref_map[ref] = old_ref
      old_ref
    end
  end
end
