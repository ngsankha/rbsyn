require "test_helper"

describe "Synthesis Benchmark" do
  it "unstage user" do
    define :unstage, "({ email: String, active: %bool, username: String, name: String}) -> User" do
      spec "correctly unstages a user" do
        pre {
          staged = User.create(name: 'Staged User', username: 'staged1', active: true, email: 'staged@account.com')
        }

        user = unstage(email: 'staged@account.com', active: true, username: 'unstaged1', name: 'Foo Bar')

        post { |user|
          assert { user.id == staged.id }
          assert { user.username == 'unstaged1' }
          assert { user.name == 'Foo Bar' }
          assert { user.active == false }
          assert { user.email == 'staged@account.com' }
        }
      end

      puts generate_program
    end
  end
end
