class RbSynError < StandardError; end

class AssertionError < RbSynError
  attr_reader :passed_count, :read_set, :write_set

  def initialize(passed_count, read_set, write_set)
    @passed_count = passed_count
    @read_set = read_set
    @write_set = write_set
  end
end
