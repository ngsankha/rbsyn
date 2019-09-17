class Table
  extend RDL::Annotate

  type 'self.where', "(``TableTypes.schema_type(trec)``) -> ``TableTypes.array_schema(trec)``", wrap: false
  type 'self.exists?', "(``TableTypes.schema_type(trec)``) -> %bool", wrap: false
end

class TableTypes
  def self.schema_type(trec)
    RDL::Type::FiniteHashType.new(trec.val.schema, nil)
  end

  def self.array_schema(trec)
    RDL::Type::GenericType.new(RDL::Type::NominalType.new(Array), trec)
  end
end
