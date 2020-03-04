# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1304
require "test_helper"

describe "Synthesis Benchmark" do
  it "clear_global_notice_if_needed" do
    skip

    define :clear_global_notice_if_needed, "TODO", [] do

      assert_equal generate_program, %{
def clear_global_notice_if_needed
  return if id < 0

  if admin && SiteSetting.has_login_hint
    SiteSetting.has_login_hint = false
    SiteSetting.global_notice = ""
  end
end
}.strip

    end
  end
end
