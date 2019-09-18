require "test_helper"
require "minitest/benchmark"

describe "Synthesizer Benchmark" do
  before(:all) do
    Table.reset
    @syn = Synthesizer.new
  end

  bench_performance_constant "can synthesize a trivial false program" do
    @syn.add_example(['BruceWayne'], false)

    prog = Unparser.unparse(@syn.run)
    assert_equal prog, "false"
  end

  bench_performance_constant "can synthesize a User exists program" do
    @syn.add_example(['bruce1'], false)

    @syn.add_example(['bruce1'], true) {
      User.new(name: 'Bruce Wayne', username: 'bruce1', email: 'bruce1@wayne.com', password: 'coolcool').save
    }

    prog = Unparser.unparse(@syn.run)
    assert_equal prog, "User.exists?(username: arg0)"
  end
end
