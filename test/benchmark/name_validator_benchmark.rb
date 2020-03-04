# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1403
require "test_helper"

describe "Synthesis Benchmark" do
  it "name_validator" do
    skip

    define :name_validator, "TODO", [] do

      assert_equal generate_program, %{
def name_validator
  if name.present?
    name_pw = name[0...User.max_password_length]
    if confirm_password?(name_pw) || confirm_password?(name_pw.downcase)
      errors.add(:name, :same_as_password)
    end
  end
end
}.strip

    end
  end
end
