require "test_helper"

describe "Synthesis Benchmark" do
  it "false" do

    define :just_false, "(String) -> %bool", [User, UserEmail] do

      spec "returns false" do
        just_false 'hello'

        post { |result|
          result == false
        }
      end

      assert_equal generate_program, %{
def just_false(arg0)
  false
end
}.strip

    end
  end
end
