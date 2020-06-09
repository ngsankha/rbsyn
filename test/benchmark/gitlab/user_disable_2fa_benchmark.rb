# https://github.com/gitlabhq/gitlabhq/blob/13150a38e701080f6c64d4925c838214a3f5ef2c/spec/models/issue_spec.rb#L511-L529

require "test_helper"

describe 'Gitlab' do
  it 'user#disable_two_factor!' do
    load_typedefs :stdlib, :active_record

    define :disable_two_factor!, '(GitlabUser) -> %bot', [GitlabUser], enable_nil: true do
      spec "clears all 2FA-related fields" do
        setup {
          @user = Fabricate(:two_factor_user)
          @old_two_factor_enabled = @user.two_factor_enabled?
          @old_encrypted_otp_secret = @user.encrypted_otp_secret
          @old_otp_backup_codes = @user.otp_backup_codes
          @old_otp_grace_period_started_at = @user.otp_grace_period_started_at
          disable_two_factor!(@user)
        }

        post { |result|
          assert { @old_two_factor_enabled }
          assert { @old_encrypted_otp_secret != nil }
          assert { @old_otp_backup_codes != @user }
          assert { @old_otp_grace_period_started_at != nil }

          assert { @user.two_factor_enabled? }
          assert { @user.encrypted_otp_secret == nil }
          assert { @user.encrypted_otp_secret_iv == nil }
          assert { @user.encrypted_otp_secret_salt == nil }
          assert { @user.otp_backup_codes == nil }
          assert { @user.otp_grace_period_started_at == nil }
        }
      end

      generate_program
    end
  end
end
