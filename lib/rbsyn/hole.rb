class HoleInfo
  attr_reader :type

  def initialize(type)
    @type = type
  end
end

class HoleVisitor < ::AST::Processor
  def on_hole(node)
    # TODO: change this
    return [Parser::AST::Node.new(:int, [2]),
    Parser::AST::Node.new(:int, [3])]
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      (k && k.is_a?(Parser::AST::Node)) ? process(k) : k
    })
  end
end
# v = HoleVisitor.new
# v.process(t)

# t = Parser::AST::Node.new(:send, [nil,
#   Parser::AST::Node.new(:sym, [:foo]),
#   Parser::AST::Node.new(:hole)])
