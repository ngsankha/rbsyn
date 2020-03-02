require "test_helper"

describe "Synthesis Benchmark" do
  it "method chains" do

    define :username_available?, "(String) -> %bool", [User, UserEmail] do

      spec "returns true when user doesn't exist" do
        pre {
          username_available? 'bruce1'
        }

        post { |result|
          assert { result == true }
        }
      end

      spec "returns false when user exists" do
        pre {
          u = Fabricate(:user)
          username_available? u.username
        }

        post { |result|
          assert { result == false }
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
