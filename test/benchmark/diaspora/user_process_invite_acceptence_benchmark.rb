# augmented: true
require "test_helper"

describe "Diaspora" do
  it "user#process_invite_acceptence" do
    load_typedefs :stdlib, :active_record

    RDL.type InvitationCode, :synth_use!, '() -> %bot', wrap: false, write: ['InvitationCode.count']

    define :process_invite_acceptence, "(DiasporaUser, InvitationCode) -> %bot", [DiasporaUser, InvitationCode] do
      spec "sets the inviter on user" do
        setup {
          @bob = Fabricate(:diaspora_user, username: 'bob')
          @inv = Fabricate(:invitation_code, :diaspora_user => @bob)
          @old_count = @inv.count
          @user = Fabricate(:diaspora_user)
          process_invite_acceptence(@user, @inv)
        }

        post { |result|
          assert { @user.invited_by_id == @bob.id }
          assert { @inv.count < @old_count }
        }
      end

      generate_program
    end
  end
end
