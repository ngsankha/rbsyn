class ExtractASTPass < ::AST::Processor
  def initialize(selection, old_env)
    @selection = selection
    @new_env = Marshal.load(Marshal.dump(old_env))
  end

  def on_filled_hole(node)
    idx = @selection.shift
    method_arg = node.children.last.fetch(:method_arg, false)
    @new_env.addnode.children[idx] if method_arg
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
