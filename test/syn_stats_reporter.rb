class SynthesisStatsReporter < Minitest::StatisticsReporter
  def before_test(result); end

  def after_test(result); end

  def record(result)
    binding.pry
  end
end
