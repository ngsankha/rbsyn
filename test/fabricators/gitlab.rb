Fabricator(:issue, class_name: GitlabIssue) do
  state { :opened }
  closed_at { nil }
  closed_by { nil }
end

Fabricator(:gitlab_user, class_name: GitlabUser) do
  otp_required_for_login { false }
end

Fabricator(:two_factor_user, from: :gitlab_user) do
  otp_required_for_login { true }
  # rand(36**l).to_s(36) yields a random string of length l
  encrypted_otp_secret { rand(36**10).to_s(36) }
  encrypted_otp_secret_iv { rand(36**10).to_s(36) }
  encrypted_otp_secret_salt { rand(36**10).to_s(36) }
  otp_backup_codes { Array.new(4) { rand(500_000_000) }.join(' ') }
  otp_grace_period_started_at { Time.now }
end
