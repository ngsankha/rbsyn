require "test_helper"
require "minitest/benchmark"

describe "Synthesizer Benchmark" do
  bench_performance_constant "synthesize a trivial false program" do
    DBUtils.reset
    syn = Synthesizer.new(components: Rbsyn::ActiveRecord::Utils.models)

    syn.add_example(['BruceWayne'], false)

    prog = Unparser.unparse(syn.run)
    assert_equal prog, "false"
  end

  bench_performance_constant "synthesize top-level lvar programs" do
    DBUtils.reset
    syn = Synthesizer.new(components: Rbsyn::ActiveRecord::Utils.models)

    syn.add_example(['foo'], 'foo')

    prog = Unparser.unparse(syn.run)
    assert_equal prog, "arg0"
  end

  bench_performance_constant "synthesize a User exists program" do
    DBUtils.reset
    syn = Synthesizer.new(components: Rbsyn::ActiveRecord::Utils.models)

    syn.add_example(['bruce1'], false)

    syn.add_example(['bruce1'], true) {
      u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
      u.emails.create(email: 'bruce1@wayne.com')
    }

    prog = Unparser.unparse(syn.run)
    assert_equal prog, "User.exists?(username: arg0)"
  end

  bench_performance_constant "synthesize method chains" do
    DBUtils.reset
    syn = Synthesizer.new(components: Rbsyn::ActiveRecord::Utils.models)

    syn.add_example(['bruce1'], true)

    syn.add_example(['bruce1'], false) {
      u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
      u.emails.create(email: 'bruce1@wayne.com')
    }

    prog = Unparser.unparse(syn.run)
    assert_equal prog, "!User.exists?(username: arg0)"
  end

  bench_performance_constant "synthesize an if condition" do
    DBUtils.reset
    class SiteSettings
      class << self
        reserved_usernames = []
        attr_accessor :reserved_usernames
      end

      def self.reserved_username?(username)
        SiteSettings.reserved_usernames.include? username
      end
    end
    RDL.type SiteSettings, 'self.reserved_username?', '(String) -> %bool', wrap: false

    syn = Synthesizer.new(max_depth: 3, components: Rbsyn::ActiveRecord::Utils.models + [SiteSettings])

    syn.add_example(['bruce1'], true)

    syn.add_example(['bruce1'], false) {
      u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
      u.emails.create(email: 'bruce1@wayne.com')
    }

    syn.add_example(['apple'], false) {
      SiteSettings.reserved_usernames = ['apple', 'dog']
    }

    prog = Unparser.unparse(syn.run)
    assert_equal prog, %{
if SiteSettings.reserved_username?(arg0)
  false
else
  !User.exists?(username: arg0)
end
}.strip
  end
end
