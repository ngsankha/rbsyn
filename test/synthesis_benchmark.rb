require "test_helper"
require "minitest/benchmark"

describe "Synthesizer Benchmark" do
  bench_performance_constant "trivial false program" do
    DBUtils.reset
    syn = Synthesizer.new(components: Rbsyn::ActiveRecord::Utils.models)

    syn.add_example(['BruceWayne'], false)

    prog = Unparser.unparse(syn.run)
    assert_equal prog, "false"
  end

  bench_performance_constant "top-level lvar programs" do
    DBUtils.reset
    syn = Synthesizer.new(components: Rbsyn::ActiveRecord::Utils.models)

    syn.add_example(['foo'], 'foo')

    prog = Unparser.unparse(syn.run)
    assert_equal prog, "arg0"
  end

  bench_performance_constant "User exists program" do
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

  bench_performance_constant "method chains" do
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

  bench_performance_constant "if condition" do
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
    syn.reset_function {
      SiteSettings.reserved_usernames = []
    }

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

  bench_performance_constant "search branch conditions during program merge" do
    DBUtils.reset
    syn = Synthesizer.new(components: Rbsyn::ActiveRecord::Utils.models)

    syn.add_example(['bruce1', nil], true)

    syn.add_example(['bruce1', 'bruce@wayne.com'], true) {
      User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
    }

    syn.add_example(['bruce1', 'bruce@wayne.com'], false) {
      u = User.create(name: 'Bruce Wayne', username: 'bruce1', password: 'coolcool')
      u.emails.create(email: 'bruce1@wayne.com')
    }

    prog = Unparser.unparse(syn.run)
    assert_equal prog, "!User.joins(:emails).exists?(username: arg0)"
  end

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
