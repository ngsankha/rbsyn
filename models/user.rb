class User < ApplicationRecord
  has_many :emails, class_name: "UserEmail"
end
