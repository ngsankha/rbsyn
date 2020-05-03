# augmented: true
require "test_helper"

describe "Diaspora" do
  it "user#confirm_email" do
    load_typedefs :stdlib, :active_record

    RDL.type String, :blank?, '() -> %bool', wrap: false
    RDL.type String, :!=, '() -> %bool', wrap: false

    define :confirm_email, "(DiasporaUser, String) -> %bool", [DiasporaUser], enable_nil: true, prog_size: 30 do
      spec 'confirms email and set the unconfirmed_email to email on valid token' do
        pre {
          @user = Fabricate(:diaspora_user)
          @user.update_attribute(:unconfirmed_email, "alice@newmail.com")
          confirm_email(@user, @user.confirm_email_token)
        }
        post { |result|
          assert { result == true }
          assert { @user.email == "alice@newmail.com" }
          assert { @user.unconfirmed_email == nil }
          assert { @user.confirm_email_token == nil }
        }
      end

      spec 'returns false and does not change anything on wrong token' do
        pre {
          @user = Fabricate(:diaspora_user)
          @user.update_attribute(:unconfirmed_email, "alice@newmail.com")
          confirm_email(@user, @user.confirm_email_token.reverse)
        }
        post { |result|
          assert { result == false }
          assert { @user.email != "alice@newmail.com" }
          assert { @user.unconfirmed_email != nil }
          assert { @user.confirm_email_token != nil }
        }
      end

      spec 'returns false and does not change anything on blank token' do
        pre {
          @user = Fabricate(:diaspora_user)
          @user.update_attribute(:unconfirmed_email, "alice@newmail.com")
          confirm_email(@user, "")
        }
        post { |result|
          assert { result == false }
          assert { @user.email != "alice@newmail.com" }
          assert { @user.unconfirmed_email != nil }
          assert { @user.confirm_email_token != nil }
        }
      end

      spec 'returns false and does not change anything on blank token' do
        pre {
          @user = Fabricate(:diaspora_user)
          @user.update_attribute(:unconfirmed_email, "alice@newmail.com")
          confirm_email(@user, nil)
        }
        post { |result|
          assert { result == false }
          assert { @user.email != "alice@newmail.com" }
          assert { @user.unconfirmed_email != nil }
          assert { @user.confirm_email_token != nil }
        }
      end

      generate_program
    end
  end
end
