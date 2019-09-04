require 'pp'
require 'test/unit'
extend Test::Unit::Assertions

class Table
  @@tables = {}

  class << self
    attr_reader :tables

    def where(args)
      rows = @@tables[self]
      return [] if rows.nil?

      rows.select { |row|
        result = true
        args.each { |k, v|
          if v.is_a? Hash
            raise NotImplementedError
          else
            result = result && (row.send(k) == v)
          end
        }
        result
      }
    end

    def exists?(args)
      self.where(args).size > 0
    end
  end

  def save
    if @@tables.has_key? self.class
      @@tables[self.class] << self
    else
      @@tables[self.class] = [self]
    end
    self
  end
end

class User < Table
  @@id = 0
  attr_accessor :id, :username, :username_lower, :password, :name

  def initialize(name:, username:, email:, password:)
    @id = @@id
    @@id += 1
    @name = name
    @username = username
    @username_lower = username.downcase
    @email = [UserEmail.new(email: email).save]
    @password = password
  end
end

class UserEmail < Table
  @@id = 0
  attr_accessor :id, :email

  def initialize(email:)
    @id = @@id
    @@id += 1
    @email = email
  end
end

class Synthesizer

  def initialize
    @states = []
    @inputs = []
    @outputs = []
    @choices = [:true, :false, :where, :exists?]
  end

  def add_example(input, output)
    # Marshal.load(Marshal.dump(o)) is an ugly way to clone objects
    @states << Marshal.load(Marshal.dump(Table.tables))
    @inputs << input
    @outputs << output
  end

  def interp(p, input)
    p.map { |expr|
      if expr.is_a? Array
        eval(expr)
      end
    }
    return nil if p.size == 0

    case p[0]
    when :true
      return true
    when :false
      return false
    when :where, :exists?
      cls = p[1]
      args = p[2..]
      return cls.send(p[0], *args)
    when :arg
      # [:arg, input_id]
      return input[p[1]]
    else
      raise NotImplementedError
    end
  end

  def run
    @choices.each { |choice|
      program = []
      case choice
      when :true
        program = [:true]
      when :false
        program = [:false]
      when :where
      when :exists?
      else
        raise NotImplementedError
      end

      checked = true
      @inputs.zip(@outputs).each { |i, o|
        result = interp(program, i)
        checked = checked && (result == o)
      }
      return program if checked
    }
    raise "Failed to find program"
  end
end

####################

s = Synthesizer.new
s.add_example(['BruceWayne'], false)

# u = User.new(name: 'Bruce Wayne', username: 'bruce1', email: 'bruce1@wayne.com', password: 'coolcool').save
# s.add_example([u.username], true)

pp s.run

# assert_equal User.exists?(username: 'bruce1'), true
