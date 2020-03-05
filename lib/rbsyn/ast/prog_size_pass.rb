class ProgSizePass < ::AST::Processor
  attr_reader :size

  def self.prog_size(node, env)
    visitor = ProgSizePass.new(env)
    visitor.process(node)
    visitor.size
  end

  def initialize(env)
    @size = 0
    @env = env
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

  # def on_hash(node)
  #   @size += 1
  #   node.children.each { |c| process(c) }
  #   nil
  # end

  def on_if(node)
    @size += (node.children.size == 3 ? 2 : 1)
    handler_missing(node)
  end

  def on_envref(node)
    process(@env.get_expr(node.children[0])[:expr])
    nil
  end

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }
  end
end
