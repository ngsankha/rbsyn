# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1139
require "test_helper"

describe "Discourse" do
  skip
  it "set_random_avatar" do
    load_typedefs :stdlib, :active_record, :random_avatar

    class SiteSetting
      class << self
        attr_accessor :selectable_avatars_enabled, :selectable_avatars
      end
    end

    RDL.type SiteSetting, 'self.selectable_avatars_enabled', '() -> %bool', wrap: false, read: ['SiteSetting.selectable_avatars_enabled']
    RDL.type SiteSetting, 'self.selectable_avatars_enabled=', '(%bool) -> %bool', wrap: false, write: ['SiteSetting.selectable_avatars_enabled']
    RDL.type SiteSetting, 'self.selectable_avatars', '() -> String', wrap: false, read: ['SiteSetting.selectable_avatars']
    RDL.type SiteSetting, 'self.selectable_avatars=', '(String) -> String', wrap: false, write: ['SiteSetting.selectable_avatars']

    define :set_random_avatar, "(User) -> %bot", [SiteSetting, User, UserAvatar, Upload] do

      spec "sets a random avatar when selectable avatars is enabled" do
        pre {
          @avatar1 = Fabricate(:upload)
          @avatar2 = Fabricate(:upload)
          SiteSetting.selectable_avatars_enabled = true
          SiteSetting.selectable_avatars = [@avatar1.url, @avatar2.url].join("\n")
          @user = Fabricate(:user)
          set_random_avatar(@user)
        }

        post { |result|
          assert { @user.uploaded_avatar_id != nil }
          assert { [@avatar1.id, @avatar2.id].include? @user.uploaded_avatar_id }
          # assert { @user.user_avatar.custom_upload_id == @user.uploaded_avatar_id }
        }
      end

      assert_equal generate_program, %{
def set_random_avatar
  if SiteSetting.selectable_avatars_enabled? && SiteSetting.selectable_avatars.present?
    urls = SiteSetting.selectable_avatars.split("\n")
    if urls.present?
      if upload = Upload.find_by(url: urls.sample)
        update_column(:uploaded_avatar_id, upload.id)
        UserAvatar.create!(user_id: id, custom_upload_id: upload.id)
      end
    end
  end
end
update_column(:uploaded_avatar_id, Upload.find_by(url: SiteSetting.selectable_avatars.split("\n").sample).id)
}.strip

    end
  end
end
