Fabricator(:user, class_name: User) do
  name { sequence(:name) { |i| "User #{i}" } }
  username { sequence(:username) { |i| "user_#{i}" } }
  password { sequence(:password) { |i| "password#{i}" } }
  emails(count: 1) { |attrs, i| Fabricate(:email) }
  # staged { false }
end

Fabricator(:email, class_name: UserEmail) do
  # primary { true }
  email { sequence(:email) { |i| "user#{i}@example.com" } }
end

Fabricator(:inactive_user, from: :user) do
  active { false }
  emails(count: 1) { |attrs, i| Fabricate(:inactive_user_email) }
  email_tokens(count: 1) { |attrs, i| Fabricate(:email_token, email: attrs[:emails].first.email) }
end

Fabricator(:inactive_user_email, from: :email) do
  primary { true }
end

Fabricator(:email_token, class_name: EmailToken) do
  expired { false }
  confirmed { false }
  token { sequence(:token) { |i| "token#{i}" } }
  email { |attrs| attrs[:email] }
end

Fabricator(:admin, from: :user) do
  admin { true }
end

Fabricator(:moderator, from: :user) do
  moderator { true }
end
