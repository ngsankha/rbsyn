require_relative "ast_node_count"
require_relative "branch_count"

class Instrumentation
  class << self
    attr_accessor :prog, :specs

    def reset!
      self.prog = nil
    end

    def size
      ASTNodeCount.size(Parser::CurrentRuby.parse(self.prog))
    end

    def branches
      BranchCount.branches(Parser::CurrentRuby.parse(self.prog))
    end
  end
end
