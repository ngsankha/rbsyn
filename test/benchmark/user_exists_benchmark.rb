require "test_helper"

describe "Synthesis Benchmark" do
  it "user exists" do

    define :username_exists?, "(String) -> %bool", [User, UserEmail] do

      spec "returns false when user doesn't exist" do
        username_exists? 'bruce1'

        post { |result|
          result == false
        }
      end

      spec "returns true when user exists" do
        pre {
          u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
          u.emails.create(email: 'bruce1@wayne.com')
        }

        username_exists? 'bruce1'

        post { |result|
          result == true
        }
      end

      assert_equal generate_program, %{
def username_exists?(arg0)
  User.exists?(username: arg0)
end
}.strip

    end
  end
end
