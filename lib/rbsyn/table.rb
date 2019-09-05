class Table
  @@tables = {}

  def self.db
    @@tables
  end

  def self.load(db)
    @@tables = db
  end

  def self.reset
    @@tables = {}
  end

  def self.where(args)
    rows = @@tables[self]
    return [] if rows.nil?

    rows.select { |row|
      args.each { |k, v|
        if v.is_a? Hash
          raise NotImplementedError
        elsif row.send(k) != v
          break false
        end
        true
      }
    }
  end

  def self.exists?(args)
    self.where(args).size > 0
  end

  def save
    if @@tables.has_key? self.class
      @@tables[self.class] << self
    else
      @@tables[self.class] = [self]
    end
    self
  end

  def self.fields
    (self.instance_methods -
      Object.instance_methods -
      [:save]).reject { |i| i.to_s[-1] == '=' }
  end
end
