require_relative "active_record"
require_relative "stdlib"

class JoinTable
end

class ActiveRecord_Relation
end

def load_typedefs(*categories)
  RDL.reset
  Rbsyn::ActiveRecord::Utils.load_schema

  categories.each { |category|
    case category
    when :stdlib
      RDL.nowrap :BasicObject
      RDL.type :BasicObject, :!, '() -> %bool', effect: [:+, :+]
      # RDL.type :BasicObject, :==, '(self) -> %bool', effect: [:+, :+]

      RDL.nowrap :Array
      RDL.type_params :Array, [:t], :all?

      RDL.nowrap :Hash
      RDL.type_params :Hash, [:k, :v], :all?
      RDL.type :Hash, :[], '(``any_or_k(trec)``) -> ``output_type(trec, targs)``', effect: [:+, :+]

    when :active_record

      ActiveRecord::Base.class_eval do
        extend RDL::Annotate

        # type 'self.create', "(``DBTypes.schema_type(trec)``) -> self", wrap: false, write: ['self']
        type 'self.where', "(``DBTypes.schema_type(trec)``) -> ``DBTypes.array_schema(trec)``", wrap: false
        type 'self.exists?', "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false
        type 'self.joins', "(``DBTypes.joins_input_type(trec)``) -> ``DBTypes.joins_output_type(trec, targs)``", wrap: false

        type :where, "(``DBTypes.schema_type(trec)``) -> ``DBTypes.array_schema(trec)``", wrap: false
        type :save, '() -> %bool', wrap: false, write: ['*']
      end

      # ActiveRecord::Querying.class_eval do
      #   extend RDL::Annotate

      #   type :where, "(``DBTypes.schema_type(trec)``) -> ``DBTypes.array_schema(trec)``", wrap: false
      # end

      JoinTable.class_eval do
        extend RDL::Annotate
        type_params [:orig, :joined], :dummy
        ## type param :orig will be nominal type of base table in join
        ## type param :joined will be a union type of all joined tables, or just a nominal type if there's only one

        ## this class is meant to only be the type parameter of ActiveRecord_Relation or WhereChain, expressing multiple joined tables instead of just a single table
      end

      ActiveRecord_Relation.class_eval do
        ## In practice, this is actually a private class nested within
        ## each ActiveRecord::Base, e.g. Person::ActiveRecord_Relation.
        ## Using this class just for type checking.
        extend RDL::Annotate

        type_params [:t], :dummy

        type :exists?, "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false
        type :first, "() -> ``DBTypes.rec_to_nominal(trec)``", wrap: false
        type :count, "() -> Integer", wrap: false
        # type :empty?, "() -> %bool", wrap: false
        # type :pluck, "(``DBTypes.pluck_input_type(trec)``) -> ``DBTypes.pluck_output_type(trec, targs)``", wrap: false
        # type :not, "(``DBTypes.schema_type(trec)``) -> ``DBTypes.array_schema(trec)``", wrap: false
        # type :update_all, "(``DBTypes.schema_type(trec)``) -> %bot", wrap: false, write: ['self']
      end

    when :ar_update
      ActiveRecord::Base.class_eval do
        extend RDL::Annotate

        type :update!, "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false, write: ['self']
        # type :update, "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false, write: ['self']
      end

      ActiveRecord_Relation.class_eval do
        extend RDL::Annotate

        type :update!, "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false, write: ['self']
        # type :update, "(``DBTypes.schema_type(trec)``) -> %bool", wrap: false, write: ['self']
      end
    else
      raise RuntimeError, "unhandled category of type definitions"
    end
  }
end
