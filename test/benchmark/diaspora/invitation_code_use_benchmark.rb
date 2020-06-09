# augmented: true
require "test_helper"

describe "Diaspora" do
  it "invitation_code#use!" do
    load_typedefs :stdlib, :active_record

    RDL.type Integer, :-, '(Integer) -> Integer', wrap: false

    define :use!, "(InvitationCode) -> %bot", [InvitationCode], consts: true do
      spec "decrements the count of the code" do
        setup {
          @code = Fabricate(:invitation_code)
          @old_count = @code.count
          use!(@code)
        }
        post { |result|
          assert { (@old_count - @code.count) == 1 }
        }
      end

      generate_program
    end
  end
end
