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
