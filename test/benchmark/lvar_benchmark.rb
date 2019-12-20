require "test_helper"

describe "Synthesis Benchmark" do
  it "lvar" do

    define :identity, "(String) -> String", [User, UserEmail] do

      spec "returns same value" do
        identity 'hello'

        post { |result|
          result == 'hello'
        }
      end

      assert_equal generate_program, %{
def identity(arg0)
  arg0
end
}.strip

    end
  end
end
