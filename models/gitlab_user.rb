class GitlabUser < ApplicationRecord
  def two_factor_enabled?
    self.otp_required_for_login
  end
end
