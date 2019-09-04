require "test_helper"

describe "Synthesizer" do
  before(:all) do
    Table.reset
    @syn = Synthesizer.new
  end

  it "can synthesize a trivial false program" do
    @syn.add_example(['BruceWayne'], false)
    prog = @syn.run
    assert_equal prog, [:false]
  end
end
