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
