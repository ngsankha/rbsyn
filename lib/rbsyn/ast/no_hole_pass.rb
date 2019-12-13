class NoHolePass < ::AST::Processor
  attr_reader :has_holes

  def self.has_hole?(node)
    visitor = NoHolePass.new
    visitor.process(node)
    visitor.has_holes
  end

  def initialize
    @has_holes = false
  end

  def on_hole(node)
    @has_holes = true
    node
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      if k.is_a?(TypedNode) && k.type == :hole
        process(k)
      else
        k
      end
    })
  end
end
