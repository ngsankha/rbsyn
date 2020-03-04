# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1469
require "test_helper"

describe "Synthesis Benchmark" do
  it "match_title_to_primary_group_changes" do
    skip

    define :match_title_to_primary_group_changes, "TODO", [] do

      assert_equal generate_program, %{
def match_title_to_primary_group_changes
  return unless primary_group_id_changed?

  if title == Group.where(id: primary_group_id_was).pluck_first(:title)
    self.title = primary_group&.title
  end
end
}.strip

    end
  end
end
