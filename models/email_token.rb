# frozen_string_literal: true

class EmailToken < ActiveRecord::Base
  belongs_to :user

  def self.confirm(token)
    token = EmailToken.find_by(token: token)
    if token.confirmed || token.expired
      raise RuntimeError, "already confirmed"
    end
    token.confirmed = true
    token.expired = false
    token.save
  end

  def active
    where(expired: false)
  end
end
