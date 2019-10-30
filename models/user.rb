class User < ApplicationRecord
  has_many :emails, class_name: "UserEmail"

  # before_save do
  #   self.username_lower = self.username.downcase
  # end
end
