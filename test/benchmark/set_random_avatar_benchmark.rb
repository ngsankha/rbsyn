# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1139
require "test_helper"

describe "Synthesis Benchmark" do
  it "set_random_avatar" do
    skip

    define :set_random_avatar, "TODO", [] do

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
}.strip

    end
  end
end
