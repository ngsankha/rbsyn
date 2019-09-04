require "test_helper"

describe "Synthesizer" do
  before(:all) do
    Table.reset
    @syn = Synthesizer.new
  end

  it "can synthesize a trivial false program" do
    input = ['BruceWayne']
    @syn.add_example(input, false)
    prog = Unparser.unparse(@syn.run)
    puts prog
    fn = eval(prog)
    assert_equal fn(*input), false
  end
end
