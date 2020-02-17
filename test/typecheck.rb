require "test_helper"

describe "Rbsyn" do
  it "typechecks" do
    RDL.reset
    require "types/core"
    require "rbsyn/sig"
    RDL.do_typecheck :later
  end
end
