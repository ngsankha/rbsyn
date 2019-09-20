class ActiveRecord::Base
  extend RDL::Annotate

  type 'self.where', "(``DBTypes.schema_type(trec)``) -> ``DBTypes.array_schema(trec)``", wrap: false
  type 'self.exists?', "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false
  type 'self.joins', "(``DBTypes.joins_input_type(trec)``) -> ``DBTypes.joins_output_type(trec)``", wrap: false
end

class JoinTable
  extend RDL::Annotate
  type_params [:orig, :joined], :dummy
  ## type param :orig will be nominal type of base table in join
  ## type param :joined will be a union type of all joined tables, or just a nominal type if there's only one

  ## this class is meant to only be the type parameter of ActiveRecord_Relation or WhereChain, expressing multiple joined tables instead of just a single table
end

class ActiveRecord_Relation
  ## In practice, this is actually a private class nested within
  ## each ActiveRecord::Base, e.g. Person::ActiveRecord_Relation.
  ## Using this class just for type checking.
  extend RDL::Annotate

  type_params [:t], :dummy

  type :exists?, "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false
end

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
          schema = schema.merge({ joined_name.to_s.pluralize.underscore.to_sym => joined_type })
        when RDL::Type::UnionType
          raise RuntimeError, "TODO: handle union type"
        else
          raise "unexpected type #{trec}"
        end
      else
        raise RuntimeError, "unknown"
      end
    else
      raise RuntimeError
    end
    RDL::Type::FiniteHashType.new(schema, nil)
  end

  def self.array_schema(trec)
    RDL::Type::GenericType.new(RDL::Type::NominalType.new(Array), trec)
  end

  def self.joins_input_type(trec)
    raise RuntimeError unless trec.is_a? RDL::Type::SingletonType
    trec = trec.val
    associations = DBUtils.get_schema(trec.name.to_sym).params[0].elts[:__associations].elts
    joins_type = nil
    associations.each { |k, v|
      if joins_type
        joins_type = RDL::Type::UnionType.new(v, joins_type)
      else
        joins_type = v
      end
    }
    joins_type = joins_type.canonical
    if joins_type.is_a? RDL::Type::UnionType
      joins_type = RDL::Type::UnionType.new(*joins_type.types.map { |t|
        raise RuntimeError, "Expected singleton here" unless t.is_a? RDL::Type::SingletonType
        RDL::Type::SingletonType.new(t.val.name.tableize.to_sym)
      })
    else
      raise RuntimeError, "Expected singleton here" unless joins_type.is_a? RDL::Type::SingletonType
      joins_type = RDL::Type::SingletonType.new(joins_type.val.name.tableize.to_sym)
    end
    joins_type
  end

  def self.joins_output_type(trec)
    tjoin = joins_input_type(trec)
    tjoin = case tjoin
    when RDL::Type::SingletonType
      RDL::Type::NominalType.new(RDL::Util.to_class(tjoin.val.to_s.classify))
    when RDL::Type::UnionType
      RDL::Type::UnionType.new(*tjoin.types.map { |t|
        raise RuntimeError, "Expected singleton here" unless t.is_a? RDL::Type::SingletonType
        RDL::Type::NominalType.new(RDL::Util.to_class(t.val.to_s.classify))
      })
    else
      raise RuntimeError, 'Unknown type'
    end
    jt = RDL::Type::GenericType.new(RDL::Type::NominalType.new(JoinTable), RDL::Type::NominalType.new(trec.val), tjoin)
    RDL::Type::GenericType.new(RDL::Type::NominalType.new(ActiveRecord_Relation), jt)
  end
end
