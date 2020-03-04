# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1532
require "test_helper"

describe "Synthesis Benchmark" do
  it "set_skip_validate_email" do
    skip

    define :set_skip_validate_email, "TODO", [] do

      assert_equal generate_program, %{
def set_skip_validate_email
  if self.primary_email
    self.primary_email.skip_validate_email = !should_validate_email_address?
  end

  true
end
}.strip

    end
  end
end
