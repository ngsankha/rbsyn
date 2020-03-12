require "test_helper"

describe "Discourse" do
  it "unstage user" do
    skip
    load_typedefs :stdlib, :active_record

    define :unstage, "({ email: ?String, active: ?%bool, username: ?String, name: ?String}) -> AnotherUser", [AnotherUser], prog_size: 20 do
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

      putsyn generate_program
    end
  end
end
