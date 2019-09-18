$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rbsyn"

require "minitest/autorun"
require "minitest/hooks/test"
require "minitest/reporters"
require "minitest/benchmark"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
