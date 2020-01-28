class NoHolePass < ::AST::Processor
  attr_reader :has_holes

  def self.has_hole?(node, env)
    visitor = NoHolePass.new(env)
    visitor.process(node)
    visitor.has_holes
  end

  def initialize(env)
    @has_holes = false
    @env = env
  end

  def on_envref(node)
    process(@env.get_expr(node.ttype, node.children[0])[:expr])
  end

  def on_hole(node)
    @has_holes = true
    node
  end

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    }
  end
end
