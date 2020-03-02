require "test_helper"

describe "Synthesis Benchmark" do
  it "lvar" do
    load_typedefs :stdlib, :active_record

    define :identity, "(String) -> String", [User, UserEmail] do

      spec "returns same value" do
        pre {
          identity 'hello'
        }

        post { |result|
          assert { result == 'hello' }
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
