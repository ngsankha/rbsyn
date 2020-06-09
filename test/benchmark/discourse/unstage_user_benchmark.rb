require "test_helper"

describe "Discourse" do
  it "unstage user" do
    load_typedefs :stdlib, :active_record

    define :unstage, "({ email: ?String, active: ?%bool, username: ?String, name: ?String}) -> AnotherUser", [AnotherUser], prog_size: 30, enable_nil: true do
      spec "correctly unstages a user" do
        setup {
          @staged = Fabricate(:staged_user, email: 'staged@account.com')
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

      spec "returns nil when the user cannot be unstaged" do
        setup {
          Fabricate(:coding_horror)
          unstage(email: 'jeff@somewhere.com')
        }

        post { |user|
          assert { user == nil }
        }
      end

      spec "returns nil when the user cannot be unstaged" do
        setup {
          unstage(email: 'ano@account.com')
        }

        post { |user|
          assert { user == nil }
        }
      end

      generate_program
    end
  end
end
