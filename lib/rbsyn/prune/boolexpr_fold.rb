class BoolExprFold < BranchPruneStrategy
  extend AST

  def self.prune(progcond)
    # we know branches are always bool (enforced when ProgTuple is created)
    # there is nothing to prune if there is no children
    return progcond unless progcond.prog.is_a? Array
    return progcond unless progcond.prog.all? { |pc| pc.prog.is_a? ProgWrapper }
    # this strategy works only when the prog body is a boolean
    # all the children will be booleans is enforced during the merge process
    return progcond unless progcond.prog[0].prog.ttype <= RDL::Globals.types[:bool]

    # the strategy works only for 2 branches
    return progcond unless progcond.prog.size == 2

    lbranch = progcond.prog[0].branch
    lbody = progcond.prog[0].prog
    rbranch = progcond.prog[1].branch
    rbody = progcond.prog[1].prog

    if lbranch.inverse?(rbranch)
      cond = BoolCond.new
      [*lbranch.conds, *rbranch.conds].each { |c|
        cond << c.to_ast
      }

      # LocalEnvironment.new is fine here because the program body is just true or false
      if lbody.to_ast.type == :true && rbody.to_ast.type == :false
        return ProgTuple.new(progcond.ctx, ProgWrapper.new(progcond.ctx, lbranch.to_ast, LocalEnvironment.new), cond,
          progcond.preconds, progcond.postconds)
      elsif lbody.to_ast.type == :false && rbody.to_ast.type == :true
        return ProgTuple.new(progcond.ctx, ProgWrapper.new(progcond.ctx, rbranch.to_ast, LocalEnvironment.new), cond,
          progcond.preconds, progcond.postconds)
      else
        return progcond
      end
    else
      return progcond
    end
  end
end
