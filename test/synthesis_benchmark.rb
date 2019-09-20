require "test_helper"
require "minitest/benchmark"

describe "Synthesizer Benchmark" do
  before(:all) do
    DBUtils.reset
    @syn = Synthesizer.new(components: Rbsyn::ActiveRecord::Utils.models)
  end

  bench_performance_constant "synthesize a trivial false program" do
    @syn.add_example(['BruceWayne'], false)

    prog = Unparser.unparse(@syn.run)
    assert_equal prog, "false"
  end

  bench_performance_constant "synthesize top-level lvar programs" do
    @syn.add_example(['foo'], 'foo')

    prog = Unparser.unparse(@syn.run)
    assert_equal prog, "arg0"
  end

  bench_performance_constant "synthesize a User exists program" do
    @syn.add_example(['bruce1'], false)

    @syn.add_example(['bruce1'], true) {
      u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
      u.emails.create(email: 'bruce1@wayne.com')
    }

    prog = Unparser.unparse(@syn.run)
    assert_equal prog, "User.exists?(username: arg0)"
  end

  bench_performance_constant "synthesize method chains" do
    skip
    @syn.add_example(['bruce1'], true)

    @syn.add_example(['bruce1'], false) {
      u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
      u.emails.create(email: 'bruce1@wayne.com')
    }

    prog = Unparser.unparse(@syn.run)
    assert_equal prog, "!User.exists?(username: arg0)"
  end

  bench_performance_constant "synthesize an if condition" do
    skip
    class SiteSettings
      class << self
        reserved_username = []
        attr_accessor :reserved_usernames
      end

      def self.reserved_username?(username)
        SiteSettings.reserved_usernames.include? username
      end
    end
    RDL.type SiteSettings, 'self.reserved_usernames?', '(String) -> %bool', wrap: false

    @syn.add_example(['bruce1'], false)

    @syn.add_example(['bruce1'], true) {
      u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
      u.emails.create(email: 'bruce1@wayne.com')
    }

    @syn.add_example(['apple'], false) {
      SiteSettings.reserved_usernames = ['apple', 'dog']
    }

    prog = Unparser.unparse(@syn.run)
    assert_equal prog, "User"
  end
end
