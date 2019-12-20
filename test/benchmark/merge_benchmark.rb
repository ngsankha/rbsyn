require "test_helper"

describe "Synthesis Benchmark" do
  it "fold branches" do

    define :username_exists?, "(String, String) -> %bool", [User, UserEmail] do

      spec "returns true when user doesn't exist" do
        username_exists? 'bruce1', nil

        post { |result|
          result == true
        }
      end

      spec "returns true when username exists without email" do
        pre {
          User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
        }

        username_exists? 'bruce1', 'bruce@wayne.com'

        post { |result|
          result == true
        }
      end

      spec "returns false when username exists with email" do
        pre {
          u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
          u.emails.create(email: 'bruce1@wayne.com')
        }

        username_exists? 'bruce1', 'bruce@wayne.com'

        post { |result|
          result == false
        }
      end

      assert_equal generate_program, %{
def username_exists?(arg0, arg1)
  !User.joins(:emails).exists?(username: arg0)
end
}.strip

    end
  end
end
