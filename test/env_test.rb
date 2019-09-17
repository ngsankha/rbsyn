require "test_helper"

describe "Environment" do
  it "allows us to save and read bindings" do
    env = Environment.new
    env[:a] = "foo"
    env[:b] = 2
    assert env[:a].type.is_a? RDL::Type::PreciseStringType
    assert_equal env[:a].value, "foo"
    assert env[:b].type.is_a? RDL::Type::SingletonType
    assert_equal env[:b].value, 2
  end

  it "allows selecting values of particular types (including subtypes)" do
    env = Environment.new
    env[:a] = "foo"
    env[:b] = 2
    env[:c] = 3.142
    ty = RDL::Type::NominalType.new(Numeric)
    bindings = env.bindings_with_type(ty)
    assert_equal bindings.size, 2
    assert_equal bindings[:b].value, 2
    assert_equal bindings[:c].value, 3.142
  end
end
