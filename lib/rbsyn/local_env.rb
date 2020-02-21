class LocalEnvironment
  @@ref = 0
  attr_accessor :info

  def initialize
    @info = {}
  end

  def next_ref
    ans = @@ref
    @@ref += 1
    ans
  end

  def bump_count(ref)
    item = @info[ref]
    item[:count] = item[:count] + 1
  end

  def get_expr(ref)
    @info[ref]
  end

  def add_expr(expr)
    ref = next_ref
    @info[ref] = {
      expr: expr,
      count: 1,
      ref: ref
    }
    ref
  end

  def exprs_with_type(type)
    @info.select { |k, v| v[:expr].ttype <= type }.keys
  end

  def +(other)
    result = LocalEnvironment.new
    result.info = @info.merge(other.info)
    result
  end
end
