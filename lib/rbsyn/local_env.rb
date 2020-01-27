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

  def add_expr(expr)
    type = expr.ttype
    @info[type] = [] if @info.key?(type)
    ref = next_ref
    exprs_with_type = @info[type] << {
      expr: expr,
      count: 1,
      ref: ref
    }
    ref
  end

  def exprs_with_type(type)
    @info.map { |k, v| v if k <= type }
      .map { |v| v[:ref] }
  end

  def +(other)
    result = LocalEnvironment.new
    [@info, other.info].each { |info|
      info.each { |type, v|
        result.info[type] = [] if result.info.key?(type)
        result.info[type].push(*v)
      }
    }
    result
  end
end
