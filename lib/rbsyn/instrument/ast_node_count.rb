class ASTNodeCount < ::AST::Processor
  attr_reader :size

  def self.size(node)
    pass = ASTNodeCount.new
    pass.process(node)
    pass.size
  end

  def initialize
    @size = 0
  end

  def handler_missing(node)
    @size += 1
    node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }
  end
end
