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
        results = progcond.prog[1].preconds.map { |precond|
          eval_ast(progcond.ctx, rbranch_guess, precond)[0] rescue nil
        }

        if results.all? true
          branch = BoolCond.new
          branch << lbranch.conds[0].to_ast
          branch << rbranch_guess.to_ast
          guessed = ProgTuple.new(progcond.ctx,
            [progcond.prog[0],
             ProgTuple.new(progcond.ctx, progcond.prog[1].prog, rbranch_guess, progcond.prog[1].preconds, progcond.prog[1].postconds)],
            branch,
            progcond.preconds, progcond.postconds)
        end
      else
        rbranch_guess = lbranch.conds[0].children[0]
        results = progcond.prog[1].preconds.map { |precond|
          eval_ast(progcond.ctx, rbranch_guess, precond)[0] rescue nil
        }
        if results.all? true
          branch = BoolCond.new
          branch << lbranch.conds[0].to_ast
          branch << rbranch_guess.to_ast
          guessed = ProgTuple.new(progcond.ctx,
            [progcond.prog[0],
             ProgTuple.new(progcond.ctx, progcond.prog[1].prog, rbranch_guess, progcond.prog[1].preconds, progcond.prog[1].postconds)],
            branch,
            progcond.preconds, progcond.postconds)
        end
      end
    rescue
    end

    return guessed unless guessed.nil?

    begin
      if rbranch.positive?
        lbranch_guess = s(RDL::Globals.types[:bool], :send, rbranch.conds[0], :!)
        results = progcond.prog[0].preconds.map { |precond|
          eval_ast(progcond.ctx, lbranch_guess, precond)[0] rescue nil
        }
        if results.all? true
          branch = BoolCond.new
          branch << rbranch.conds[0].to_ast
          branch << lbranch_guess.to_ast
          guessed = ProgTuple.new(progcond.ctx,
            [ProgTuple.new(progcond.ctx, progcond.prog[0].prog, lbranch_guess, progcond.prog[0].preconds, progcond.prog[0].postconds),
             progcond.prog[1]],
            branch,
            progcond.preconds, progcond.postconds)
        end
      else rbranch.negative?
        lbranch_guess = rbranch.conds[0].children[0]
        results = progcond.prog[0].preconds.map { |precond|
          eval_ast(progcond.ctx, lbranch_guess, precond)[0] rescue nil
        }
        if results.all? true
          branch = BoolCond.new
          branch << rbranch.conds[0].to_ast
          branch << lbranch_guess.to_ast
          guessed = ProgTuple.new(progcond.ctx,
            [ProgTuple.new(progcond.ctx, progcond.prog[0].prog, lbranch_guess, progcond.prog[0].preconds, progcond.prog[0].postconds),
             progcond.prog[1]],
            branch,
            progcond.preconds, progcond.postconds)
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
