$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rbsyn"
require "fabrication"
require_relative "../models/model_helper"
require_relative "../components/component_helper"

require "minitest/autorun"
require "minitest/hooks/test"
require "minitest/reporters"

class Object
  include SpecDSL
end

Fabrication.configure do |config|
  config.fabricator_path = 'fabricators'
  config.path_prefix = 'test'
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

Rbsyn::ActiveRecord::Utils.load_schema
