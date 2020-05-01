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
            schema[k] = RDL::Globals.types[:bool]
          when "Datetime"
            # tname = "DateTime or Time"
            # schema[k] = RDL::Type::UnionType.new(RDL::Type::NominalType.new(Time), RDL::Type::NominalType.new(DateTime))
            tname = "Time"
            schema[k] = RDL::Type::NominalType.new(Time)
          when "Text"
            tname = "String"
            schema[k] = RDL::Globals.types[:string]
          else
            schema[k] = RDL::Type::NominalType.new(tname)
          end
          RDL.type model, "#{k}=".to_sym, "(#{tname}) -> #{tname}", wrap: false, write: ["#{model}.#{k}"]
          RDL.type model, k.to_sym,         "() -> #{tname}", wrap: false, read: ["#{model}.#{k}"]
        }
        schema = schema.transform_keys { |k| k.to_sym }
        assoc = {}
        model.reflections.each { |assoc_name, assoc_info|
          kl_type = RDL::Type::SingletonType.new(RDL::Util.to_class(assoc_info.class_name))
          if assoc[assoc_name]
            assoc[assoc_name] = RDL::Type::UnionType.new(assoc[assoc_name], kl_type)
          else
            assoc[assoc_name] = kl_type unless assoc[assoc_name]
          end

          if assoc_info.name.to_s.pluralize == assoc_info.name.to_s
            RDL.type model, "#{assoc_info.name}".to_sym, "() -> ActiveRecord_Relation<#{assoc_info.class_name}>", wrap: false, read: ["self", "#{assoc_info.class_name}"]
            RDL.type model, "#{assoc_info.name}=".to_sym, "(Array<#{assoc_info.class_name}>) -> ActiveRecord_Relation<#{assoc_info.class_name}>", wrap: false, write: ["#{assoc_info.class_name}"]
          else
            RDL.type model, "#{assoc_info.name}".to_sym, "() -> #{assoc_info.class_name}", wrap: false, read: ["self", "#{assoc_info.class_name}"]
            RDL.type model, "#{assoc_info.name}=".to_sym, "(#{assoc_info.class_name}) -> #{assoc_info.class_name}", wrap: false, write: ["#{assoc_info.class_name}"]
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