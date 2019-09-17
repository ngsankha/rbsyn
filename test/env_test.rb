require "test_helper"

describe "Environment" do
  before(:all) do
    @env = ValEnvironment.new
    @env[:a] = "foo"
    @env[:b] = 2
  end

  it "allows us to save and read bindings" do
    assert @env[:a].type.is_a? RDL::Type::PreciseStringType
    assert_equal @env[:a].value, "foo"
    assert @env[:b].type.is_a? RDL::Type::SingletonType
    assert_equal @env[:b].value, 2
  end

  it "allows selecting values of particular types (including subtypes)" do
    @env[:c] = 3.142
    ty = RDL::Type::NominalType.new(Numeric)
    bindings = @env.bindings_with_type(ty)
    assert_equal bindings.size, 2
    assert_equal bindings[:b].value, 2
    assert_equal bindings[:c].value, 3.142
  end

  describe "ValEnvironment" do
    it "is an Environment" do
      assert ValEnvironment < Environment
    end

    it "can produce a type environment" do
      tenv = @env.to_type_env
      assert tenv.is_a? TypeEnvironment
      assert_equal tenv.size, 2
      assert tenv[:a].type.is_a? RDL::Type::PreciseStringType
      assert tenv[:b].type.is_a? RDL::Type::SingletonType
    end
  end

  describe "TypeEnvironment" do
    it "is an Environment" do
      assert TypeEnvironment < Environment
    end

    it "can merge type environments" do
      other = ValEnvironment.new
      other[:b] = 3
      tenv1 = @env.to_type_env
      tenv2 = other.to_type_env
      tenv = tenv1.merge(tenv2)
      assert_equal tenv.size, 2
      assert tenv[:a].type.is_a? RDL::Type::PreciseStringType
      assert tenv[:b].type.is_a? RDL::Type::UnionType
      assert_equal Set.new(tenv[:b].type.types.map(&:val)), Set[2, 3]
    end
  end
end
