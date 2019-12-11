class ValBinding
  attr_reader :name, :type
  attr_accessor :value

  def initialize(name, value)
    @name = name
    @value = value
    case value
    when Numeric, String, TrueClass, FalseClass, NilClass
      @type = RDL::Globals.parser.scan_str("#T #{value.inspect}")
    when Hash
      @type = infer_hash_type(value)
    else
      raise RuntimeError, "Expected value to be a string or number, got #{value}"
    end
  end

  def to_s
    @value.to_s
  end

  def infer_hash_type(value)
    raise RuntimeError, "expected hash" unless value.is_a? Hash
    thash = {}
    value.each { |k, v|
      t = case v
      when Numeric, String, TrueClass, FalseClass, NilClass
        RDL::Globals.parser.scan_str("#T #{v.inspect}")
      when Hash
        infer_hash_type(v)
      else
        raise RuntimeError, "unhandled type of value"
      end
      thash[k.to_sym] = t
    }
    RDL::Type::FiniteHashType.new(thash, nil)
  end
end

class TypeBinding
  attr_reader :name, :type

  def initialize(name, type)
    @name = name
    @type = type
  end

  def to_s
    "T<#{@type.to_s}>"
  end
end

class Environment
  def initialize
    @var_map = {}
  end

  def [](key)
    @var_map[key]
  end

  def bindings_with_type(type)
    @var_map.select { |k, v|
      v.type <= type
    }
  end

  def bindings_with_supertype(type)
    @var_map.select { |k, v|
      type <= v.type
    }
  end

  def bindings
    @var_map.keys
  end

  def has_binding?(name)
    @var_map.key? name
  end

  def size
    @var_map.size
  end

  def to_s
    "{#{@var_map.map{ |k, v| "#{k}: #{v}" }.join(', ')}}"
  end
end

class ValEnvironment < Environment
  def []=(key, val)
    raise RuntimeError if val.is_a? RDL::Type::Type
    @var_map[key] = ValBinding.new(key, val)
  end

  def to_type_env
    tenv = TypeEnvironment.new
    @var_map.each { |k, v|
      tenv[k] = v.type
    }
    tenv
  end
end

class TypeEnvironment < Environment
  def []=(key, val)
    raise RuntimeError unless val.is_a? RDL::Type::Type
    @var_map[key] = TypeBinding.new(key, val)
  end

  def merge(other)
    tenv = TypeEnvironment.new
    @var_map.each { |k, v|
      tenv[k] = v.type
    }
    other.bindings.each { |b|
      unless tenv.has_binding? b
        tenv[b] = other[b].type
      else
        tenv[b] = RDL::Type::UnionType.new(tenv[b].type, other[b].type).canonical
      end
    }
    tenv
  end
end
