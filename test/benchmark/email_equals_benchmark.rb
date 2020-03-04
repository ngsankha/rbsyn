# benchmark: true
# source: https://github.com/discourse/discourse/blob/bd49d4af1a19feb303f0658ae51bfeba81687519/app/models/user.rb#L1194
require "test_helper"

describe "Synthesis Benchmark" do
  it "email=" do
    skip

    define :email=, "TODO", [] do

      assert_equal generate_program, %{
def email=(new_email)
  if primary_email
    new_record? ? primary_email.email = new_email : primary_email.update(email: new_email)
  else
    self.primary_email = UserEmail.new(email: new_email, user: self, primary: true)
  end
end
}.strip

    end
  end
end
