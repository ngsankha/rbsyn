require_relative "ast_node_count"
require_relative "branch_count"

class Instrumentation
  class << self
    attr_accessor :prog, :specs

    def reset!
      self.prog = nil
    end

    def size
      return 0 unless self.prog
      ASTNodeCount.size(Parser::CurrentRuby.parse(self.prog))
    end

    def branches
      return 0 unless self.prog
      BranchCount.branches(Parser::CurrentRuby.parse(self.prog))
    end
  end
end
