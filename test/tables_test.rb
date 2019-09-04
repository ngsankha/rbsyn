require "test_helper"

describe "Tables" do
  before(:all) do
    Table.reset
  end

  it "can insert entries" do
    u = User.new(name: 'Bruce Wayne', username: 'bruce1', email: 'bruce1@wayne.com', password: 'coolcool').save
    db = Table.db
    assert db.has_key? User
    assert db.has_key? UserEmail
    assert_equal db.keys.size, 2
    assert_equal db[User].size, 1
    assert_equal db[UserEmail].size, 1
  end

  it "can search entries" do
    u1 = User.new(name: 'Bruce Wayne', username: 'bruce1', email: 'bruce1@wayne.com', password: 'coolcool').save
    u2 = User.new(name: 'Bruce Wayne', username: 'brUce2', email: 'bruce2@wayne.com', password: 'coolcool').save
    assert_equal User.where(username: u1.username, id: u1.id)[0], u1
    assert_equal User.where(username: u1.username)[0], u1
    assert_equal User.where(username: 'bruce2').size, 0
  end

  it "runs other code that models include" do
    u1 = User.new(name: 'Bruce Wayne', username: 'bruce1', email: 'bruce1@wayne.com', password: 'coolcool').save
    assert_equal User.where(username_lower: u1.username.downcase)[0], u1
  end

  it "searching with non-existent fields throw error" do
    u1 = User.new(name: 'Bruce Wayne', username: 'bruce1', email: 'bruce1@wayne.com', password: 'coolcool').save
    assert_raises(NoMethodError) {
      User.where(lol: 'wut')
    }
  end

  it "can check if entries exist" do
    u1 = User.new(name: 'Bruce Wayne', username: 'bruce1', email: 'bruce1@wayne.com', password: 'coolcool').save
    u2 = User.new(name: 'Bruce Wayne', username: 'brUce2', email: 'bruce2@wayne.com', password: 'coolcool').save
    assert User.exists?(username: u1.username, id: u1.id)
    assert User.exists?(username: u1.username)
    refute User.exists?(username: 'bruce2')
  end
end
