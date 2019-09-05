require "test_helper"

describe "Synthesizer" do
  before(:all) do
    Table.reset
    @syn = Synthesizer.new
  end

  it "can synthesize a trivial false program" do
    input = ['BruceWayne']
    output = false
    @syn.add_example(input, output)

    prog = Unparser.unparse(@syn.run)
    puts prog
    fn = eval(prog)

    assert_equal fn(*input), output
  end

  it "can synthesize a User exists program" do
    @syn.add_example(['bruce1'], false)

    User.new(name: 'Bruce Wayne', username: 'bruce1', email: 'bruce1@wayne.com', password: 'coolcool').save
    input = ['bruce1']
    output = true
    @syn.add_example(input, output)

    prog = Unparser.unparse(@syn.run)
    puts prog
    fn = eval(prog)

    assert_equal fn(*input), output
  end
end
