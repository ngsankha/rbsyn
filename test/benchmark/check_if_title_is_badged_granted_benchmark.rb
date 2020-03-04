# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1491
require "test_helper"

describe "Synthesis Benchmark" do
  it "check_if_title_is_badged_granted" do
    skip

    define :check_if_title_is_badged_granted, "TODO", [] do

      assert_equal generate_program, %{
def check_if_title_is_badged_granted
  if title_changed? && !new_record? && user_profile
    badge_matching_title = title && badges.find do |badge|
      badge.allow_title? && (badge.display_name == title || badge.name == title)
    end
    user_profile.update(
      badge_granted_title: badge_matching_title.present?,
      granted_title_badge_id: badge_matching_title&.id
    )
  end
end
}.strip

    end
  end
end
