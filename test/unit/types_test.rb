require "test_helper"

describe "TableTypes" do
  it "type checks table methods" do
    class Foo
      def bar1
        User.exists?(username: "bar")
      end
    end
    RDL.type Foo, :bar1, "() -> %bool", wrap: false, typecheck: :later1
    RDL.do_typecheck :later1
  end

  it "type checks joins" do
    class Foo
      def bar2
        User.joins(:emails)
      end
    end
    RDL.type Foo, :bar2, "() -> ActiveRecord_Relation<JoinTable<User, UserEmail>>", wrap: false, typecheck: :later2
    RDL.do_typecheck :later2
  end

  it "type checks joins followed by exists" do
    class Foo
      def bar3
        User.joins(:emails).exists?(username: "bar", emails: { email: "bar@foo.com" })
      end
    end
    RDL.type Foo, :bar3, "() -> %bool", wrap: false, typecheck: :later3
    RDL.do_typecheck :later3
  end
end
