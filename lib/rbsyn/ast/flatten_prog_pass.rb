VAR_PREFIX = "t"

class FlattenProgramPass < ::AST::Processor
  include AST

  attr_reader :var_expr

  def initialize(ctx, env)
    @ctx = ctx
    @env = env
    @var_expr = {}
  end

  def on_envref(node)
    subexpr = @env.get_expr(node.children[0])
    if subexpr[:count] == 1
      subexpr[:expr]
    else
      ref = @ctx.to_ctx_ref(subexpr[:ref])
      @var_expr[ref] = subexpr[:expr]
      s(subexpr[:expr].ttype, :lvar, "#{VAR_PREFIX}#{ref}".to_sym)
    end
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
