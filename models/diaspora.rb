require 'securerandom'

class InvitationCode < ApplicationRecord
  belongs_to :diaspora_user
  before_create :generate_token

  def generate_token
    begin
      self.token = SecureRandom.hex(6)
    end while InvitationCode.exists?(:token => self[:token])
  end

  def synth_use!
    self.count=(self.count - 1)
    true
  end

end

class DiasporaUser < ApplicationRecord
  belongs_to :invited_by, class_name: "DiasporaUser", optional: true
  has_many :invited_users, class_name: "DiasporaUser", inverse_of: :invited_by, foreign_key: :invited_by_id
end
