require 'securerandom'

class InvitationCode < ApplicationRecord
  # belongs_to :diaspora_user
  before_create :generate_token

  def generate_token
    begin
      self.token = SecureRandom.hex(6)
    end while InvitationCode.exists?(:token => self[:token])
  end
end

# class DiasporaUser < ApplicationRecord
# end
