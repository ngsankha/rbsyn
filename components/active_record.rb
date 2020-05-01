class DBTypes
  def self.table_name_to_schema_hash(table)
    schema = DBUtils.get_schema(table).params[0]
    Hash[schema.elts.except(:__associations).map { |k, v|
      [k, RDL::Type::OptionalType.new(v)]
    }]
  end

  def self.schema_type(trec)
    case trec
    when RDL::Type::SingletonType
      trec = trec.val
      schema = table_name_to_schema_hash(trec.name.to_sym)
    when RDL::Type::NominalType
      schema = table_name_to_schema_hash(trec.name.to_sym)
    when RDL::Type::VarType
      raise RuntimeError, "expected only Symbol" unless trec.name.is_a? Symbol
      schema = table_name_to_schema_hash(trec.name)
    when RDL::Type::GenericType
      raise RuntimeError unless trec.base.klass == ActiveRecord_Relation
      param = trec.params[0]
      case param
      when RDL::Type::GenericType
        raise RuntimeError unless param.base.klass == JoinTable
        base_name = param.params[0].klass.to_s.singularize.to_sym
        schema = table_name_to_schema_hash(base_name)
        joined_to = param.params[1]
        case joined_to
        when RDL::Type::NominalType
          ## just one table joined to base table
          joined_name = joined_to.klass.to_s.singularize.to_sym
          joined_type = RDL::Type::OptionalType.new(RDL::Type::FiniteHashType.new(table_name_to_schema_hash(joined_name), nil))
          field_name = param.params[0].klass.reflect_on_all_associations.find { |a| joined_name.to_s == a.class_name }.name
          schema = schema.merge({ field_name.to_sym => joined_type })
        when RDL::Type::UnionType
          raise RuntimeError, "TODO: handle union type"
        else
          raise "unexpected type #{trec}"
        end
      when RDL::Type::NominalType
        schema = table_name_to_schema_hash(param.name.to_sym)
      when RDL::Type::VarType
        raise RuntimeError, "expected only Symbol" unless param.name.is_a? Symbol
        schema = table_name_to_schema_hash(param.name)
      else
        raise RuntimeError, "unknown: #{param.inspect}"
      end
    when RDL::Type::UnionType
      return RDL::Type::UnionType.new(*trec.types.map { |t| schema_type(t) }).canonical
    else
      raise RuntimeError
    end
    RDL::Type::FiniteHashType.new(schema, nil)
  end

  def self.rec_to_nominal(trec)
    case trec
    when RDL::Type::UnionType
      return RDL::Type::UnionType.new(*trec.types.map { |t| rec_to_nominal(t) }).canonical
    when RDL::Type::GenericType
      raise RuntimeError, "got unexpected type #{trec}" unless trec.base.klass == ActiveRecord_Relation
      param = trec.params[0]
      case param
      when RDL::Type::NominalType
        return param
      when RDL::Type::GenericType
        raise RuntimeError, "expected only JoinTable" unless param.base.klass == JoinTable
        return param.params[0]
      else
        raise RuntimeError, "unhandled type"
      end
    else
      raise RuntimeError, "unhandled type"
    end
  end

  def self.array_schema(trec)
    case trec
    when RDL::Type::SingletonType
      RDL::Type::GenericType.new(RDL::Type::NominalType.new(ActiveRecord_Relation), RDL::Type::NominalType.new(trec.val))
    when RDL::Type::NominalType
      RDL::Type::GenericType.new(RDL::Type::NominalType.new(ActiveRecord_Relation), trec)
    when RDL::Type::GenericType
      raise RuntimeError, "expected only ActiveRecord_Relation" if trec.base.name != "ActiveRecord_Relation"
      array_schema(trec.params[0])
    else
      raise RuntimeError, "unexpected type #{trec}"
    end
  end

  def self.joins_input_type(trec)
    raise RuntimeError unless trec.is_a? RDL::Type::SingletonType
    trec = trec.val
    associations = DBUtils.get_schema(trec.name.to_sym).params[0].elts[:__associations].elts
    joins_type = RDL::Type::UnionType.new(*associations.keys.map { |k| RDL::Type::SingletonType.new(k.to_sym) })
    joins_type.canonical
  end

  def self.joins_output_type(trec, targs)
    case targs[0]
    when RDL::Type::UnionType
      RDL::Type::UnionType.new(*targs[0].types.map { |t| joins_output_type(trec, [t]) }).canonical
    when RDL::Type::SingletonType
      trec = trec.val
      tjoined = DBUtils.get_schema(trec.name.to_sym).params[0].elts[:__associations].elts[targs[0].val.to_s]
      raise RuntimeError, "Association doesn't exist" if tjoined.nil?
      tjoin = RDL::Type::NominalType.new(tjoined.val)
      jt = RDL::Type::GenericType.new(RDL::Type::NominalType.new(JoinTable), RDL::Type::NominalType.new(trec), tjoin)
      RDL::Type::GenericType.new(RDL::Type::NominalType.new(ActiveRecord_Relation), jt)
    else
      raise RuntimeError, "can handle only singletons"
    end
  end

  def self.pluck_input_type(trec)
    finite_hash = schema_type(trec)
    RDL::Type::UnionType.new(*finite_hash.elts.keys.map { |sym| RDL::Type::SingletonType.new(sym) })
  end

  def self.pluck_output_type(trec, targs)
    case targs[0]
    when RDL::Type::UnionType
      RDL::Type::UnionType.new(*targs[0].types.map { |t| pluck_output_type(trec, [t]) })
    else
      finite_hash = schema_type(trec)
      val_type = finite_hash.elts[targs[0].val]
      val_type = val_type.type if val_type.is_a? RDL::Type::OptionalType
      RDL::Type::GenericType.new(RDL::Type::NominalType.new(Array), val_type)
    end
  end
end
