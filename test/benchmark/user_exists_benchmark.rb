require "test_helper"

describe "Synthesis Benchmark" do
  it "user exists" do
    load_typedefs :stdlib, :active_record

    define :username_exists?, "(String) -> %bool", [User, UserEmail] do

      spec "returns false when user doesn't exist" do
        pre {
          username_exists? 'bruce1'
        }

        post { |result|
          assert { result == false }
        }
      end

      spec "returns true when user exists" do
        pre {
          u = Fabricate(:user)
          username_exists? u.username
        }

        post { |result|
          assert { result == true }
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
