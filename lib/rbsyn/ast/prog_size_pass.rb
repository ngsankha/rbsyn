class ProgSizePass < ::AST::Processor
  attr_reader :size

  def self.prog_size(node)
    visitor = ProgSizePass.new
    visitor.process(node)
    visitor.size
  end

  def initialize
    @size = 0
  end

  def on_hole(node)
    @size += node.children[0]
    node
  end

  def on_send(node)
    @size += 1
    handler_missing(node)
    node
  end

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }
  end
end
