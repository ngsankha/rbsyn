class FlattenProgramPass < ::AST::Processor
  def initialize(env)
    @env = env
  end

  def on_envref(node)
    subexpr = @env.get_expr(node.ttype, node.children[0])
    subexpr[:expr]
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
