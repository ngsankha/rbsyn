ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :username
    t.string :password
    t.boolean :staged
    t.boolean :active
    t.boolean :admin
    t.boolean :moderator
  end
  create_table :user_emails, force: true do |t|
    t.string :email
    t.boolean :primary
    t.references :user
  end
  create_table :email_tokens, force: true do |t|
    t.string :email
    t.string :token
    t.boolean :confirmed
    t.boolean :expired
    t.references :user
  end
  create_table :another_users, force: true do |t|
    t.string :name
    t.string :username
    t.string :password
    t.boolean :staged
    t.string :email
    t.boolean :active
  end
  create_table :posts, force: true do |t|
    t.string :created_by
    t.string :slug
    t.string :title
  end
  create_table :demo_users, force: true do |t|
    t.string :name
    t.string :username
    t.boolean :admin
  end
  create_table :gitlab_issues, force: true do |t|
    t.integer :state_id
    t.datetime :closed_at
    t.references :closed_by
  end
  create_table :gitlab_users, force: true do |t|
    t.boolean :otp_required_for_login
    t.string :encrypted_otp_secret
    t.string :encrypted_otp_secret_iv
    t.string :encrypted_otp_secret_salt
    t.string :otp_backup_codes
    t.datetime :otp_grace_period_started_at
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

require_relative "user"
require_relative "user_email"
require_relative "email_token"
require_relative "another_user"
require_relative "post"
require_relative "demo_user"
require_relative "gitlab_issue"
require_relative "gitlab_user"
