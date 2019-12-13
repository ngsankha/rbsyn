class ExtractASTPass < ::AST::Processor
  def initialize(selection)
    @selection = selection
  end

  def on_filled_hole(node)
    idx = @selection.shift
    node.children[idx]
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
