class DBUtils
  @@schema = {}

  def self.set_schema(klass, schema)
    @@schema[klass] = schema
  end

  def self.get_schema(klass)
    @@schema[klass]
  end

  def self.reset
    Rbsyn::ActiveRecord::Utils.reset
  end
end
