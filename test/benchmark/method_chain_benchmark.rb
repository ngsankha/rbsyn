require "test_helper"

describe "Synthesis Benchmark" do
  it "method chains" do

    define :username_available?, "(String) -> %bool" do

      spec "returns true when user doesn't exist" do
        username_available? 'bruce1'

        post { |result|
          result == true
        }
      end

      spec "returns false when user exists" do
        pre {
          u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
          u.emails.create(email: 'bruce1@wayne.com')
        }

        username_available? 'bruce1'

        post { |result|
          result == false
        }
      end

      assert_equal generate_program, %{
def username_available?(arg0)
  !User.exists?(username: arg0)
end
}.strip

    end
  end
end
