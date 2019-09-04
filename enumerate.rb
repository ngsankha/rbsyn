require 'test/unit'
extend Test::Unit::Assertions

class Table
  @@tables = {}

  attr_reader :tables

  def save
    if @@tables.has_key? self.class
      @@tables[self.class] << self
    else
      @@tables[self.class] = [self]
    end
    self
  end

  def self.where(args)
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

  def self.exists?(args)
    self.where(args).size > 0
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
    @email = [UserEmail.new(email: email)]
    @password = password
    super
  end
end

class UserEmail < Table
  @@id = 0
  attr_accessor :id, :email

  def initialize(email:)
    @id = @@id
    @@id += 1
    @email = email
    super
  end
end

class Synthesizer
  @states = []
  @inputs = []
  @outputs = []

  def add_example(input, output)
    # Marshal.load(Marshal.dump(o)) is an ugly way to clone objects
    @states << Marshal.load(Marshal.dump(Table.tables))
    @inputs << input
    @outputs << output
  end

  def run
    
  end
end

####################

s = Synthesizer.new
s.add_example(['BruceWayne'], false)

u = User.new(name: 'Bruce Wayne', username: 'bruce1', email: 'bruce1@wayne.com', password: 'coolcool').save
s.add_example([u.username], true)

puts s.run

# assert_equal User.exists?(username: 'bruce1'), true
