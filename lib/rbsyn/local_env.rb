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
    @info.each { |k, v|
      v.each { |entry|
        if entry[:ref] == ref
          entry[:count] = entry[:count] + 1
          return
        end
      }
    }
  end

  def get_expr(type, ref)
    @info[type].find { |i| i[:ref] == ref }
  end

  def add_expr(expr)
    type = expr.ttype
    @info[type] = RDL.type_cast([],
        'Array<{ expr: TypedNode, count: Integer, ref: Integer }>',
        force: true) unless @info.key?(type)
    ref = next_ref
    exprs_with_type = @info[type] << {
      expr: expr,
      count: 1,
      ref: ref
    }
    ref
  end

  def exprs_with_type(type)
    RDL.type_cast(@info.select { |k, v| k <= type }
      .values.flatten, 'Array<{ expr: TypedNode, count: Integer, ref: Integer }>', force: true)
      .map { |v| v[:ref] }
  end

  def +(other)
    result = LocalEnvironment.new
    [@info, other.info].each { |info|
      info.each { |type, v|
        result.info[type] = RDL.type_cast([],
        'Array<{ expr: TypedNode, count: Integer, ref: Integer }>',
        force: true) unless result.info.key?(type)
        result.info[type].push(*v)
      }
    }
    result
  end
end
