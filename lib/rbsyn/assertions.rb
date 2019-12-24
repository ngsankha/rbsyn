module Assertions
  def assert(&blk)
    ans = yield
    if !!ans
      ans
    else
      raise AssertionError, "testing"
    end
  end
end
