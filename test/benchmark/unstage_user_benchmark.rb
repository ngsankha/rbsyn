require "test_helper"

describe "Synthesis Benchmark" do
  it "unstage user" do
    define :unstage,
    "({ email: ?String, active: ?%bool, username: ?String, name: ?String}) -> AnotherUser",
    [AnotherUser], prog_size: 20 do
      spec "correctly unstages a user" do
        pre {
          @dummy = AnotherUser.create(name: 'Dummy User', username: 'dummy1', active: true, email: 'dummy@account.com')
          @staged = AnotherUser.create(name: 'Staged User', username: 'staged1', active: true, email: 'staged@account.com')
        }

        user = unstage(email: 'staged@account.com', active: true, username: 'unstaged1', name: 'Foo Bar')

        post { |user|
          assert { user.id == @staged.id }
          assert { user.username == 'unstaged1' }
          assert { user.name == 'Foo Bar' }
          assert { user.active == false }
          assert { user.email == 'staged@account.com' }
        }
      end

      assert_equal generate_program, %{
def unstage(arg0)
  t4 = AnotherUser.where(email: arg0.[](:email)).first
  t4.username=arg0.[](:username)
  t4.name=arg0.[](:name)
  t4.active=false
  t4
end
}.strip
    end
  end
end
