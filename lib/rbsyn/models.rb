class UserEmail < Table
  @@id = 0
  @@schema = {
    id: RDL::Type::OptionalType.new(RDL::Type::NominalType.new(Integer)),
    email: RDL::Type::OptionalType.new(RDL::Type::NominalType.new(String))
  }

  attr_accessor :id, :email

  def self.schema
    @@schema
  end

  def initialize(email:)
    @id = @@id
    @@id += 1
    @email = email
  end
end

class User < Table
  @@id = 0
  @@schema = {
    id: RDL::Type::OptionalType.new(RDL::Type::NominalType.new(Integer)),
    username: RDL::Type::OptionalType.new(RDL::Type::NominalType.new(String)),
    username_lower: RDL::Type::OptionalType.new(RDL::Type::NominalType.new(String)),
    password: RDL::Type::OptionalType.new(RDL::Type::NominalType.new(String)),
    name: RDL::Type::OptionalType.new(RDL::Type::NominalType.new(String)),
    email: RDL::Type::OptionalType.new(RDL::Type::GenericType.new(RDL::Type::NominalType.new(Array), RDL::Type::NominalType.new(UserEmail)))
  }

  attr_accessor :id, :username, :username_lower, :password, :name, :email

  def self.schema
    @@schema
  end

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
