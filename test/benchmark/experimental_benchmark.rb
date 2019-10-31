require "test_helper"

describe "Synthesis Benchmark" do
  it "false" do
    skip

  # bench_performance_constant "search branch conditions during program merge 2" do
  #   DBUtils.reset
  #   syn = Synthesizer.new(components: Rbsyn::ActiveRecord::Utils.models)

  #   syn.add_example(['bruce1', nil], true)

  #   syn.add_example(['bruce1', nil], false) {
  #     u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
  #     u.emails.create(email: 'bruce1@wayne.com', primary: false)
  #   }

  #   syn.add_example(['bruce2', 'bruce2@wayne.com'], false) {
  #     staged = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool', staged: true)
  #     staged.emails.create(email: 'bruce1@wayne.com', primary: true)

  #     user = User.create(name: 'Bruce Wayne', username: 'bruce2', password: 'coolcool', staged: false)
  #     user.emails.create(email: 'bruce2@wayne.com', primary: true)
  #   }

  #   prog = Unparser.unparse(syn.run)
  #   assert_equal prog, "!User.joins(:emails).exists?(username: arg0)"
  # end
  end
end
