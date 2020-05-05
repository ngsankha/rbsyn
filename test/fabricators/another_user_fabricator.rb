Fabricator(:another_user, class_name: AnotherUser) do
  name { sequence(:name) { |i| "User #{i}" } }
  username { sequence(:username) { |i| "user_#{i}" } }
  password { sequence(:password) { |i| "password#{i}" } }
  email { sequence(:email) { |i| "email#{i}@example.com" } }
  staged { false }
  active { true }
end

Fabricator(:staged_user, from: :another_user) do
  staged { true }
end

Fabricator(:coding_horror, from: :another_user) do
  email { 'jeff@somewhere.com' }
end
