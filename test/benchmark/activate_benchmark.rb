# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L941
# This benchmark doesn't work as it is - since the precondition is same for 2 tests and the postcondition is different
# Our engine is unable to discover a branch condition that is able to tell the functions apart or get 2 programs same
require "test_helper"

describe "Synthesis Benchmark" do
  it "activate" do
    load_typedefs :stdlib, :active_record, :ar_update

    define :activate, "(User) -> %bot", [User, EmailToken], prog_size: 30 do
      class Fabricate
        def self.inactive_user
          u = User.create(username: 'user1', password: 'secret', active: false)
          u.emails.create(email: 'user1@example.com', primary: true)
          u.email_tokens.create(email: 'user1@example.com', expired: false, confirmed: false, token: 'temp_token4')
          u
        end
      end

      RDL.type User, :email, '() -> String', read: ['UserEmail'], write: []
      RDL.type User, :email_confirmed?, '() -> %bool', read: ['EmailToken'], write: []
      RDL.type EmailToken, 'self.confirm', '(String) -> %bool', read: [], write: ['EmailToken']
      RDL.type EmailToken, :active, '() -> ActiveRecord_Relation<EmailToken>', read: ['EmailToken'], write: []

      spec "confirms email token and activates user" do
        pre {
          @inactive = Fabricate(:inactive_user)
          activate(@inactive)
        }

        post { |result|
          @inactive.reload
          assert { @inactive.email_confirmed? }
          assert { @inactive.active }
        }
      end

      # spec 'works without needing to reload the model' do
      #   pre {
      #     @inactive = Fabricate(:inactive_user)
      #     activate(@inactive)
      #   }

      #   post { |result|
      #     assert { @inactive.email_confirmed? }
      #     assert { @inactive.active }
      #   }
      # end

      spec 'activates user even if email token is already confirmed' do
        pre {
          @inactive = Fabricate(:inactive_user)
          token = @inactive.email_tokens.find_by(email: @inactive.email)
          token.update_column(:confirmed, true)
          activate(@inactive)
        }

        post { | result|
          assert { @inactive.active }
        }
      end

      assert_equal generate_program, %{
def activate(arg0)
  if EmailToken.exists?(confirmed: false)
    arg0.update!(active: true)
    arg0.email_tokens.first.update!(confirmed: true)
  else
    arg0.active=true
    true
  end
end
}.strip
    end
  end
end
