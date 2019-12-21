ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :username
    t.string :username_lower
    t.string :password
    t.boolean :staged
  end
  create_table :user_emails, force: true do |t|
    t.string :email
    t.boolean :primary
    t.references :user
  end
  create_table :another_users, force: true do |t|
    t.string :name
    t.string :username
    t.string :username_lower
    t.string :password
    t.boolean :staged
    t.string :email
    t.boolean :active
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

require_relative "user"
require_relative "user_email"
require_relative "another_user"
