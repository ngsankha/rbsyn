require "test_helper"

describe "Models" do
  before(:all) do
    User.delete_all
    UserEmail.delete_all
  end

  it "basic operations" do
    u = User.create(name: 'Bruce Wayne', username: 'bruce', password: 'coolcool')
    u.emails.create(email: 'bruce@wayne.com')

    q = User.find_by(username: 'bruce')
    assert_equal q.name, 'Bruce Wayne'
    assert_equal q.emails[0].email, 'bruce@wayne.com'
  end
end
