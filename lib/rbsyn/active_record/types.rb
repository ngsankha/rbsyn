class ActiveRecord::Base
  extend RDL::Annotate

  type 'self.where', "(``DBTypes.schema_type(trec)``) -> ``DBTypes.array_schema(trec)``", wrap: false
  type 'self.exists?', "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false
end

class DBTypes
  def self.schema_type(trec)
    raise RuntimeError unless trec.is_a? RDL::Type::SingletonType
    trec = trec.val
    schema = DBUtils.get_schema(trec.name.to_sym).params[0]
    schema = schema.elts.except(:__associations).map { |k, v|
      [k, RDL::Type::OptionalType.new(v)]
    }
    RDL::Type::FiniteHashType.new(schema, nil)
  end

  def self.array_schema(trec)
    RDL::Type::GenericType.new(RDL::Type::NominalType.new(Array), trec)
  end
end
