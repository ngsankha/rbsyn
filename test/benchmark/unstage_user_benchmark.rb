require "test_helper"

describe "Synthesis Benchmark" do
  it "unstage user" do
    define :unstage,
    "({ email: ?String, active: ?%bool, username: ?String, name: ?String}) -> AnotherUser",
    [AnotherUser], prog_size: 20 do
      spec "correctly unstages a user" do
        pre {
          @dummy = Fabricate(:another_user)
          @staged = Fabricate(:another_user, email: 'staged@account.com')
          unstage(email: 'staged@account.com', active: true, username: 'unstaged1', name: 'Foo Bar')
        }

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
  t0 = AnotherUser.where(email: arg0.[](:email)).first
  t0.username=arg0.[](:username)
  t0.name=arg0.[](:name)
  t0.active=false
  t0
end
}.strip
    end
  end
end
