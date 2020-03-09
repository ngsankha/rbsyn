require "test_helper"

describe "Synthesis Benchmark" do
  it "false" do
    load_typedefs :stdlib, :active_record

    define :just_false, "(String) -> %bool", [User, UserEmail] do

      spec "returns false" do
        pre {
          just_false 'hello'
        }

        post { |result|
          assert { result == false }
        }
      end

      putsyn generate_program
    end
  end
end
