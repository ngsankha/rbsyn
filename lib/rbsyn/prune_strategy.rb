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

    lbranch = progcond.prog[0].branch
    lbody = progcond.prog[0].prog.expr
    rbranch = progcond.prog[1].branch
    rbody = progcond.prog[1].prog.expr

    if lbranch.inverse?(rbranch)
      cond = BoolCond.new
      [*lbranch.conds, *rbranch.conds].each { |c|
        cond << TypedAST.new(RDL::Globals.types[:bool], c)
      }

      if lbody.type == :true && rbody.type == :false
        return ProgTuple.new(progcond.ctx,
          TypedAST.new(RDL::Globals.types[:bool], lbranch.to_ast),
          cond,
          progcond.envs, progcond.setups)
      elsif lbody.type == :false && rbody.type == :true
        return ProgTuple.new(progcond.ctx,
          TypedAST.new(RDL::Globals.types[:bool], rbranch.to_ast),
          cond,
          progcond.envs, progcond.setups)
      else
        return progcond
      end
    else
      return progcond
    end
  end
end

class InverseBranchFold < BranchPruneStrategy
  extend AST

  def self.prune(progcond)
    return progcond unless progcond.prog.is_a? Array
    return progcond unless progcond.prog.size == 2

    lbranch = progcond.prog[0].branch
    lbody = progcond.prog[0].prog.expr
    rbranch = progcond.prog[1].branch
    rbody = progcond.prog[1].prog.expr

    if lbranch.inverse?(rbranch)
      cond = BoolCond.new
      [*lbranch.conds, *rbranch.conds].each { |c|
        cond << TypedAST.new(RDL::Globals.types[:bool], c)
      }

      begin
        # these may throw exception if the positive? is not known
        lbranch_bool = lbranch.positive?
        rbranch_bool = rbranch.positive?

        if lbranch_bool != rbranch_bool
          if lbranch_bool
            return ProgTuple.new(progcond.ctx,
              TypedAST.new(progcond.prog[0].prog.type, s(:if, lbranch.to_ast, lbody, rbody)),
              cond,
              progcond.envs, progcond.setups)
          else
            return ProgTuple.new(progcond.ctx,
              TypedAST.new(progcond.prog[0].prog.type, s(:if, rbranch.to_ast, rbody, lbody)),
              cond,
              progcond.envs, progcond.setups)
          end
        else
          return progcond
        end
      rescue
        return progcond
      end
    else
      return progcond
    end
  end
end
