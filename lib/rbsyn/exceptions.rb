class AssertionError < StandardError
  attr_reader :read_set, :write_set

  def initialize(read_set, write_set)
    @read_set = read_set
    @write_set = write_set
  end
end
