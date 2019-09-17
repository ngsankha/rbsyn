class TypeBinding
  attr_reader :name, :type
  attr_accessor :value

  def initialize(name, value)
    @name = name
    @value = value
    case value
    when Numeric, String
      @type = RDL::Globals.parser.scan_str("#T #{value.inspect}")
    else
      raise RuntimeError, "Expected value to be a string or number"
    end
  end
end

class Environment < Hash
  def initialize
    @var_map = {}
  end

  def []=(key, val)
    @var_map[key] = TypeBinding.new(key, val)
  end

  def [](key)
    @var_map[key]
  end

  def bindings_with_type(type)
    @var_map.select { |k, v|
      v.type <= type
    }
  end

  def bindings
    @var_map.keys
  end

  def size
    @var_map.size
  end
end