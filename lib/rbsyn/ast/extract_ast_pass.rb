class ExtractASTPass < ::AST::Processor
  def initialize(selection, old_env)
    @selection = selection
    @old_env = old_env
    @new_env = @old_env.dup
  end

  def on_filled_hole(node)
    idx = @selection.shift
    method_arg = node.children.last.fetch(:method_arg, false)
    @new_env.add_expr()
    node.children[idx]
  end

  def env
    @new_env
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
