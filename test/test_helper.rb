$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rbsyn"
require "fabrication"
require_relative "../models/model_helper"
require_relative "../components/component_helper"

require "minitest/autorun"
require "minitest/hooks/test"
require "minitest/reporters"

require_relative "syn_stats_reporter"

class Object
  include SpecDSL
end

Fabrication.configure do |config|
  config.fabricator_path = 'fabricators'
  config.path_prefix = 'test'
end

reporters = [Minitest::Reporters::SpecReporter.new]
# reporters << SynthesisStatsReporter.new(ENV['INSTRUMENTATION']) if ENV.key? 'INSTRUMENTATION'
reporters << SynthesisStatsReporter.new('test_log.json')
Minitest::Reporters.use! reporters

Rbsyn::ActiveRecord::Utils.load_schema
