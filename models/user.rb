class User < ApplicationRecord
  has_many :emails, class_name: "UserEmail"
  has_many :email_tokens, dependent: :destroy

  def email
    emails.find_by(primary: true).email
  end

  def email_confirmed?
    !email_tokens.where(email: email, confirmed: true).empty?
  end
end
