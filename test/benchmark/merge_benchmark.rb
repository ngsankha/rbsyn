require "test_helper"

describe "Synthesis Benchmark" do
  it "fold branches" do

    define :username_exists?, "(String, String) -> %bool", [User, UserEmail] do

      spec "returns true when user doesn't exist" do
        pre {
          username_exists? 'bruce1', nil
        }

        post { |result|
          assert { result == true }
        }
      end

      spec "returns true when username exists without email" do
        pre {
          u = Fabricate(:user)
          Fabricate(:email, email: 'bruce@wayne.com')
          username_exists? u.username, 'bruce@wayne.com'
        }

        post { |result|
          assert { result == true }
        }
      end

      spec "returns false when username exists with email" do
        pre {
          u = Fabricate(:user)
          u.emails.create(email: 'bruce@wayne.com')
          username_exists? u.username, 'bruce@wayne.com'
        }

        post { |result|
          assert { result == false }
        }
      end

      assert_equal generate_program, %{
def username_exists?(arg0, arg1)
  !UserEmail.joins(:user).exists?(email: arg1)
end
}.strip
    end
  end
end
