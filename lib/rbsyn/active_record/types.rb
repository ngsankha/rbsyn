class ActiveRecord::Base
  extend RDL::Annotate

  type 'self.where', "(``DBTypes.schema_type(trec)``) -> ``DBTypes.array_schema(trec)``", wrap: false
  type 'self.exists?', "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false
  type 'self.joins', "(``DBTypes.joins_input_type(trec)``) -> ``DBTypes.joins_output_type(trec, targs)``", wrap: false
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
  type :first, "() -> ``DBTypes.rec_to_nominal(trec)``", wrap: false
  type :empty?, "() -> %bool", wrap: false
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
    else
      raise RuntimeError
    end
    RDL::Type::FiniteHashType.new(schema, nil)
  end

  def self.rec_to_nominal(trec)
    case trec
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
    else
      raise RuntimeError, "unexpected type"
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
    raise RuntimeError, "Expected only argument that is a singleton" if targs.size > 1 || !targs[0].is_a?(RDL::Type::SingletonType)
    trec = trec.val
    tjoined = DBUtils.get_schema(trec.name.to_sym).params[0].elts[:__associations].elts[targs[0].val.to_s]
    raise RuntimeError, "Association doesn't exist" if tjoined.nil?
    tjoin = RDL::Type::NominalType.new(tjoined.val)
    jt = RDL::Type::GenericType.new(RDL::Type::NominalType.new(JoinTable), RDL::Type::NominalType.new(trec), tjoin)
    RDL::Type::GenericType.new(RDL::Type::NominalType.new(ActiveRecord_Relation), jt)
  end
end
