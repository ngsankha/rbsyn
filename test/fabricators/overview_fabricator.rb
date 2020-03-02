Fabricator(:demo_user, class_name: DemoUser) do
  name { sequence(:name) { |i| "Demo User #{i}" } }
  username { sequence(:username) { |i| "user_#{i}" } }
  admin { false }
end

Fabricator(:post, class_name: Post) do
  slug { sequence(:slug) { |i| "post-#{i}" } }
  title { sequence(:title) { |i| "Post #{i}" } }
end
