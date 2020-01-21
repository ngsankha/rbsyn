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
        cond << c
      }

      if lbody.to_ast.type == :true && rbody.to_ast.type == :false
        return ProgTuple.new(progcond.ctx, ProgWrapper.new(progcond.ctx, lbranch.to_ast), cond,
          progcond.preconds, progcond.args)
      elsif lbody.to_ast.type == :false && rbody.to_ast.type == :true
        return ProgTuple.new(progcond.ctx, ProgWrapper.new(progcond.ctx, rbranch.to_ast), cond,
          progcond.preconds, progcond.args)
      else
        return progcond
      end
    else
      return progcond
    end
  end
end

class SpeculativeInverseBranchFold < BranchPruneStrategy
  extend AST

  def self.prune(progcond)
    return progcond unless progcond.prog.is_a? Array
    return progcond unless progcond.prog.size == 2

    lbranch = progcond.prog[0].branch
    rbranch = progcond.prog[1].branch

    guessed = nil

    begin
      if lbranch.positive?
        rbranch_guess = s(RDL::Globals.types[:bool], :send, lbranch.conds[0], :!)
        results = progcond.prog[1].args.zip(progcond.prog[1].preconds).map { |arg, precond|
          eval_ast(progcond.ctx, rbranch_guess, arg, precond)[0] rescue nil
        }

        if results.all?
          branch = BoolCond.new
          branch << lbranch.conds[0]
          branch << rbranch_guess
          guessed = ProgTuple.new(progcond.ctx,
            [progcond.prog[0],
             ProgTuple.new(progcond.ctx, progcond.prog[1].prog, rbranch_guess, progcond.prog[1].preconds, progcond.prog[1].args)],
            branch,
            progcond.preconds, progcond.args)
        end
      else
        rbranch_guess = lbranch.conds[0].children[0]
        results = progcond.prog[1].args.zip(progcond.prog[1].preconds).map { |arg, precond|
          eval_ast(progcond.ctx, rbranch_guess, arg, precond)[0] rescue nil
        }
        if results.all?
          branch = BoolCond.new
          branch << lbranch.conds[0]
          branch << rbranch_guess
          guessed = ProgTuple.new(progcond.ctx,
            [progcond.prog[0],
             ProgTuple.new(progcond.ctx, progcond.prog[1].prog, rbranch_guess, progcond.prog[1].preconds, progcond.prog[1].args)],
            branch,
            progcond.preconds, progcond.args)
        end
      end
    rescue
    end

    return guessed unless guessed.nil?

    begin
      if rbranch.positive?
        lbranch_guess = s(RDL::Globals.types[:bool], :send, rbranch.conds[0], :!)
        results = progcond.prog[0].args.zip(progcond.prog[0].preconds).map { |arg, precond|
          eval_ast(progcond.ctx, lbranch_guess, arg, precond)[0] rescue nil
        }
        if results.all?
          branch = BoolCond.new
          branch << rbranch.conds[0]
          branch << lbranch_guess
          guessed = ProgTuple.new(progcond.ctx,
            [ProgTuple.new(progcond.ctx, progcond.prog[0].prog, lbranch_guess, progcond.prog[0].preconds, progcond.prog[0].args),
             progcond.prog[1]],
            branch,
            progcond.preconds, progcond.args)
        end
      else rbranch.negative?
        lbranch_guess = rbranch.conds[0].children[0]
        results = progcond.prog[0].args.zip(progcond.prog[0].preconds).map { |arg, precond|
          eval_ast(progcond.ctx, lbranch_guess, arg, precond)[0] rescue nil
        }
        if results.all?
          branch = BoolCond.new
          branch << rbranch.conds[0]
          branch << lbranch_guess
          guessed = ProgTuple.new(progcond.ctx,
            [ProgTuple.new(progcond.ctx, progcond.prog[0].prog, lbranch_guess, progcond.prog[0].preconds, progcond.prog[0].args),
             progcond.prog[1]],
            branch,
            progcond.preconds, progcond.args)
        end
      end
    rescue
    end

    unless guessed.nil?
      return guessed
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
    lbody = progcond.prog[0].prog.to_ast
    rbranch = progcond.prog[1].branch
    rbody = progcond.prog[1].prog.to_ast

    if lbranch.inverse?(rbranch)
      cond = BoolCond.new
      [*lbranch.conds, *rbranch.conds].each { |c|
        cond << c
      }

      begin
        # these may throw exception if the positive? is not known
        lbranch_bool = lbranch.positive?
        rbranch_bool = rbranch.positive?

        if lbranch_bool != rbranch_bool
          if lbranch_bool
            return ProgTuple.new(progcond.ctx,
              ProgWrapper.new(progcond.ctx,
                s(progcond.prog[0].prog.ttype, :if, lbranch.to_ast, lbody, rbody)),
              cond,
              progcond.preconds, progcond.args)
          else
            return ProgTuple.new(progcond.ctx,
              ProgWrapper.new(progcond.ctx,
                s(progcond.prog[0].prog.ttype, :if, rbranch.to_ast, rbody, lbody)),
              cond,
              progcond.preconds, progcond.args)
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
