require "test_helper"

describe "Synthesizer" do
  before(:all) do
    Table.reset
    @syn = Synthesizer.new
  end

  it "can synthesize a trivial false program" do
    @syn.add_example(['BruceWayne'], false)

    prog = Unparser.unparse(@syn.run)
    puts "\n#{prog}"
  end

  it "can synthesize a User exists program" do
    @syn.add_example(['bruce1'], false)

    @syn.add_example(['bruce1'], true) {
      User.new(name: 'Bruce Wayne', username: 'bruce1', email: 'bruce1@wayne.com', password: 'coolcool').save
    }

    prog = Unparser.unparse(@syn.run)
    puts "\n#{prog}"
  end
end
