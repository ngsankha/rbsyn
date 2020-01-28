VAR_PREFIX = "t"

class FlattenProgramPass < ::AST::Processor
  include AST

  attr_reader :var_expr

  @@counter = 0

  def initialize(env)
    @env = env
    @var_expr = {}
  end

  def on_envref(node)
    subexpr = @env.get_expr(node.ttype, node.children[0])
    if subexpr[:count] == 1
      subexpr[:expr]
    else
      @var_expr[@@counter] = subexpr[:expr]
      @@counter += 1
      s(subexpr[:expr].ttype, :lvar, "#{VAR_PREFIX}#{@@counter - 1}".to_sym)
    end
  end

  def on_hole(node)
    raise RuntimeError, "unable to flatten program"
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
