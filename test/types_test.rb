require "test_helper"

describe "TableTypes" do

  class Useless
    def foo
      User.exists?(username: "bar")
    end
  end

  it "type checks table methods" do
    RDL.type Useless, :foo, "() -> %bool", wrap: false, typecheck: :later
    RDL.do_typecheck :later
  end
end
