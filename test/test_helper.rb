$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rbsyn"
require_relative "../models/model_helper"

require "minitest/autorun"
require "minitest/hooks/test"
require "minitest/reporters"

class Object
  include SpecDSL
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

Rbsyn::ActiveRecord::Utils.load_schema
