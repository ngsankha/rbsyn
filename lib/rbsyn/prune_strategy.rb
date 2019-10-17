class BranchPruneStrategy
  def self.prune(progcond)
    raise RuntimeError, "Not implemented"
  end
end

class BoolExprFold < BranchPruneStrategy
  extend AST

  def self.prune(progcond)
    # we know branches are always bool (enforced when ProgTuple is created)
    # there is nothing to prune if there is no children
    return progcond unless progcond.prog.is_a? Array
    # this strategy works only when the prog body is a boolean
    # all the children will be booleans is enforced during the merge process
    return progcond unless progcond.prog[0].prog.type <= RDL::Globals.types[:bool]

    # the strategy works only for 2 branches
    return progcond unless progcond.prog.size == 2

    lbranch = progcond.prog[0].branch.expr
    lbody = progcond.prog[0].prog.expr
    rbranch = progcond.prog[1].branch.expr
    rbody = progcond.prog[1].prog.expr

    # puts "#{Unparser.unparse(lbranch)} -------- #{Unparser.unparse(rbranch)}"

    if lbranch.type == :send && lbranch.children[1] == :! && rbranch == lbranch.children[0]
      # require 'pry'; binding.pry
      # lbranch = !p, rbranch = p
      if lbody.type == :true && rbody.type == :false
        return ProgTuple.new(progcond.prog[0].branch,
          TypedAST.new(RDL::Globals.types[:bool], s(:true)),
          progcond.envs, progcond.setups)
      elsif lbody.type == :false && rbody.type == :true
        return ProgTuple.new(progcond.prog[1].branch,
          TypedAST.new(RDL::Globals.types[:bool], s(:true)),
          progcond.envs, progcond.setups)
      else
        raise RuntimeError, "unexpected"
      end
    elsif rbranch.type == :send && rbranch.children[1] == :! && lbranch == rbranch.children[0]
      # require 'pry'; binding.pry
      # lbranch = p, rhs = !p
      if rbody.type == :true && lbody.type == :false
        return ProgTuple.new(progcond.prog[1].branch,
          TypedAST.new(RDL::Globals.types[:bool], s(:true)),
          progcond.envs, progcond.setups)
      elsif rbody.type == :false && lbody.type == :true
        return ProgTuple.new(progcond.prog[0].branch,
          TypedAST.new(RDL::Globals.types[:bool], s(:true)),
          progcond.envs, progcond.setups)
      else
        raise RuntimeError, "unexpected"
      end
    else
      return progcond
    end
  end
end
