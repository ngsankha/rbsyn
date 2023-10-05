require "test_helper"

describe "Sketch" do
  it "does arithmetic without sketch" do
    skip
    load_typedefs :stdlib

    define :sketch_1, "(Integer) -> Integer", [], consts: true do

      spec "returns 3x + 1" do
        setup {
          sketch_1 5
        }

        post { |result|
          assert { result == 16 }
        }
      end

      generate_program
    end
  end

  it "does arithmetic with sketch" do
    load_typedefs :stdlib

    src = File.join(__dir__, "arith_1_sketch.rb")

    sketch src, :sketch_1, "(Integer) -> Integer", [], consts: true do

      spec "returns 3x + 1" do
        setup {
          sketch_1 5
        }

        post { |result|
          assert { result == 16 }
        }
      end

      generate_program
    end
  end
end
