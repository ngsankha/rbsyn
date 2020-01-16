module Assertions
  # Note: The same count will correspond to the same failure reason all the time
  def assert(&blk)
    @count += 1
    ans = yield
    if !!ans
      ans
    else
      # TODO: change this
      if @count == 1
        read_set = [[AnotherUser, "id"]]
        write_set = []
      elsif @count == 2
        read_set = [[AnotherUser, "username"]]
        write_set = []
      end
      raise AssertionError.new(read_set, write_set), "testing"
    end
  end
end
