class LocalEnvironment
  attr_accessor :base_expr

  def initialize
    @ref = 0
    @info = {}
  end

  def next_ref
    ans = @ref
    @ref += 1
    ans
  end

  def add_expr(expr)
    type = expr.ttype
    @info[type] = [] if @info.key?(type)
    exprs_with_type = @info[type] << {
      expr: expr,
      count: 1,
      ref: next_ref
    }
  end

  def exprs_with_type(type)
    @info.map { |k, v| v if k <= type }
      .map { |v| v[:ref] }
  end
end
