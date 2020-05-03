Fabricator(:invitation_code, class_name: InvitationCode) do
  count { 3 }
end

Fabricator(:diaspora_user, class_name: DiasporaUser) do
  username { sequence(:user) { |i| "user_#{i}" } }
  unconfirmed_email { sequence(:email) { |i| "user#{i}@example.com" } }
  confirm_email_token { SecureRandom.hex(6) }
end
