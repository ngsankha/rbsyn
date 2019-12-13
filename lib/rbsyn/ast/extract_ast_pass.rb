class ExtractASTPass < ::AST::Processor
  def initialize(selection)
    @selection = selection
  end

  def on_filled_hole(node)
    idx = @selection.shift
    node.children[idx]
  end

  def handler_missing(node)
    if k.is_a?(TypedNode) && k.type == :filled_hole
        process(k)
      else
        k
      end
  end
end
