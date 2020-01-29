module Assertions
  # Note: The same count will correspond to the same failure reason all the time
  def assert(&blk)
    @count += 1
    ans = yield
    if !!ans
      @passed_count += 1
      ans
    else
      # TODO: change this
      if @count == 1
        read_set = [[AnotherUser, :id]]
        write_set = []
      elsif @count == 2
        read_set = [[AnotherUser, :username]]
        write_set = []
      elsif @count == 3
        read_set = [[AnotherUser, :name]]
        write_set = []
      elsif @count == 4
        read_set = [[AnotherUser, :active]]
        write_set = []
      elsif @count == 5
        read_set = [[AnotherUser, :email]]
        write_set = []
      end
      raise AssertionError.new(@passed_count, read_set, write_set), "testing"
    end
  end
end
