ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :username
    t.string :username_lower
    t.string :password
  end
  create_table :user_emails, force: true do |t|
    t.string :email
    t.references :user
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class User < ApplicationRecord
  has_many :emails, class_name: "UserEmail"
end

class UserEmail < ApplicationRecord
  belongs_to :user
end
