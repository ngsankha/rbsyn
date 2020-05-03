Fabricator(:invitation_code, class_name: InvitationCode) do
  count { 3 }
end

Fabricator(:diaspora_user, class_name: DiasporaUser) do
  username { sequence(:user) { |i| "user_#{i}" } }
end

Fabricator(:diaspora_user_with_token, from: :diaspora_user) do
  username { sequence(:user) { |i| "user_#{i}" } }
  unconfirmed_email { sequence(:email) { |i| "user#{i}@example.com" } }
  confirm_email_token { SecureRandom.hex(6) }
end

Fabricator(:pod, class_name: DiasporaPod) do
  # scheduled_check { false }
  transient :status

  after_create { |pod, transients|
    pod.update!(status: DiasporaPod.status_codes[transients[:status] || :unchecked])
    # pod.update!(status: DiasporaPod.status_codes[transients[:status]])
  }
end
