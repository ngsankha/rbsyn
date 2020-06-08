class BranchCount < ::AST::Processor
  attr_reader :branches

  def self.branches(node)
    pass = BranchCount.new
    pass.process(node)
    pass.branches == 0 ? 1 : pass.branches
  end

  def initialize
    @branches = 0
  end

  def on_if(node)
    if node.children.size == 2
      @branches += 1 unless node.children[1].type == :if
      process(node.children[1])
    elsif node.children.size == 3
      @branches += 1 unless node.children[1].type == :if
      @branches += 1 unless node.children[2].type == :if
      process(node.children[1])
      process(node.children[2])
    else
      raise RbSynError, "unexpected"
    end
  end

  def handler_missing(node)
    node.children.map { |k|
      k.is_a?(node.class) ? process(k) : k
    }
  end
end
