require "test_helper"

describe "Synthetic" do
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

      generate_program
    end
  end
end
