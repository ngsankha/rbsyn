class SynthesisStatsReporter < Minitest::StatisticsReporter
  def initialize(path)
    super
    @path = path
    @results_agg = {}
  end

  def before_test(test)
    Instrumentation.reset!
  end

  def after_test(test)
    return unless test.passed?
    putsyn Instrumentation.prog if ENV.key? 'CONSOLE_LOG'
  end

  def record(result)
    @results_agg[result.klass] = {} unless @results_agg.key? result.klass
    return unless result.passed?
    @results_agg[result.klass][result.name] = {
      time: result.time,
      size: Instrumentation.size,
      branches: Instrumentation.branches,
      specs: Instrumentation.specs,
      components: RDL::Globals.info.info.map { |k, v| v.size }.sum
    }
  end

  def report
    File.write(@path, @results_agg.to_json)
  end

  def putsyn(src)
    formatter = Rouge::Formatters::Terminal256.new
    lexer = Rouge::Lexers::Ruby.new
    puts formatter.format(lexer.lex(src))
  end
end
