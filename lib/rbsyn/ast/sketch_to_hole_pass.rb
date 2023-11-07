class SketchToHolePass < ::AST::Processor
  include AST

  def initialize
    @methods = []
  end

  def on_send(node)
    if node.children[0].nil? && node.children[1] == :_?
      s(RDL::Globals.types[:integer], :hole, 0, {})
    else
      handler_missing(node)
    end
  end

  def on_def(node)
    @methods << node.children[0]
    @tenv = []
    @ret = RDL::Globals.types[:integer]
    new_nodes = node.children.map { |k|
      k.is_a?(Parser::AST::Node) ? process(k) : k
    }
    meth_type = RDL::Type::MethodType.new(@tenv.values, nil, @ret)
    TypedNode.new(meth_type, node.type, *new_nodes)
  end

  def on_args(node)
    node.children.each { |arg|
      @tenv[arg.children[0]] = RDL::Globals.types[:integer]
    }
  end

  def handler_missing(node)
    # This is used when parsing Sketches, so all nodes are untyped hence an instance of Parser::AST::Node
    TypedNode.new(RDL::Globals.types[:integer], node.type,
      *node.children.map { |k|
        k.is_a?(Parser::AST::Node) ? process(k) : k
      })
  end
end
