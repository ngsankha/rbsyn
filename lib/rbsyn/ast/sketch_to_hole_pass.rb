class SketchToHolePass < ::AST::Processor
  include AST

  def on_send(node)
    if node.children[0].nil? && node.children[1] == :_?
      s(RDL::Globals.types[:top], :hole, 0)
    else
      handler_missing(node)
    end
  end

  def handler_missing(node)
    # This is used when parsing Sketches, so all nodes are untyped hence an instance of Parser::AST::Node
    TypedNode.new(RDL::Globals.types[:top], node.type,
      *node.children.map { |k|
        k.is_a?(Parser::AST::Node) ? process(k) : k
      })
  end
end
