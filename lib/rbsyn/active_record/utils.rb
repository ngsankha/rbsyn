module Rbsyn::ActiveRecord
  RESERVED_NAMES = ["ApplicationRecord", "primary::SchemaMigration", "ActiveRecord::InternalMetadata", "ActiveRecord::SchemaMigration"]

  class Utils
    def self.models
      ActiveRecord::Base.descendants.reject { |model|
        Rbsyn::ActiveRecord::RESERVED_NAMES.include? model.name.to_s
      }
    end

    def self.reset
      models.each(&:delete_all)
    end

    def self.load_schema
      models = ActiveRecord::Base.descendants.each { |m|
        m.send(:load_schema) unless m.abstract_class? rescue nil
      }
      models.each { |model|
        next if RESERVED_NAMES.include? model.to_s
        RDL.nowrap(model)
        schema = {}
        model.columns_hash.each { |k, v|
          tname = v.type.to_s.camelize
          case tname
          when "Boolean"
            tname = "%bool"
            schema[k] = RD::Globals.types[:bool]
          when "Datetime"
            tname = "DateTime or Time"
            schema[k] = RDL::Type::UnionType.new(RDL::Type::NominalType.new(Time), RDL::Type::NominalType.new(DateTime))
          when "Text"
            tname = "String"
            schema[k] = RDL::Globals.types[:string]
          else
            schema[k] = RDL::Type::NominalType.new(tname)
          end
          RDL.type model, "#{k}=".to_sym, "(#{tname}) -> #{tname}", wrap: false
          RDL.type model, k.to_s,         "() -> #{tname}", wrap: false
        }
        schema = schema.transform_keys { |k| k.to_sym }
        assoc = {}
        model.reflect_on_all_associations.each { |a|
          kl_type = RDL::Type::SingletonType.new(a.name)
          aname = a.macro
          if assoc[aname]
            assoc[aname] = RDL::Type::UnionType.new(assoc[aname], kl_type)
          else
            assoc[aname] = kl_type unless assoc[aname]
          end

          if a.name.to_s.pluralize == a.name.to_s
            RDL.type model, a.name, "() -> ActiveRecord_Relation<#{a.name.to_s.singularize}>", wrap: false
          else
            RDL.type model, a.name, "() -> #{a.name.to_s.camelize.singularize}", wrap: false
          end
        }
        schema[:__associations] = RDL::Type::FiniteHashType.new(assoc, nil)
        base_name = model.to_s
        base_type = RDL::Type::NominalType.new(base_name)
        hash_type = RDL::Type::FiniteHashType.new(schema, nil)
        schema = RDL::Type::GenericType.new(base_type, hash_type)
        DBUtils.set_schema base_name.to_sym, schema
      }
    end
  end
end