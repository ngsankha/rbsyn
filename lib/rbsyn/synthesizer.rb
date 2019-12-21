COVARIANT = :+
CONTRAVARIANT = :-
TRUE_POSTCOND = Proc.new { |result| result == true }

class Synthesizer
  include AST
  include SynHelper

  def initialize(ctx)
    @ctx = ctx
  end

  def run
    @ctx.load_tenv!
    # seed_hole = s(@ctx.functype.ret, :hole, 0, @ctx.fn_call_depth)

    progconds = @ctx.preconds.zip(@ctx.args, @ctx.postconds).map { |precond, arg, postcond|
      progs = generate(
        s(@ctx.functype.ret, :hole, 0, @ctx.fn_call_depth, {}),
        [precond], [arg], [postcond], true)
      branches = generate(
        s(RDL::Globals.types[:bool], :hole, 0, @ctx.fn_call_depth, {bool_consts: false}),
        [precond], [arg], [TRUE_POSTCOND], true)
      progs.product(branches).map { |prog, branch| ProgTuple.new(@ctx, prog, branch, [precond], [arg]) }
    }

    # if there is only one generated, there is nothing to merge, we return the first synthesized program
    return progconds[0][0].prog if progconds.size == 1

    # TODO: we need to merge only the program with different body
    # (same programs with different branch conditions are wasted work?)
    completed = progconds.reduce { |merged_prog, progcond|
      results = []
      merged_prog.each { |mp|
        progcond.each { |pp|
          possible = (mp + pp)
          possible.each { |t| t.prune_branches }
          results.push(*possible)
        }
      }

      # TODO: eliminate incorrect programs by testing?
      # TODO: ordering?
      # EliminationStrategy.descendants.each { |strategy|
      #   results = strategy.eliminate(results)
      # }
      results = DuplicateElimiation.eliminate(results)
      results = BranchCountElimination.eliminate(results)
      results
    }

    completed.each { |progcond|
      ast = progcond.to_ast
      test_outputs = @ctx.preconds.zip(@ctx.args, @ctx.postconds).map { |precond, arg, postcond|
        res = eval_ast(@ctx, ast, arg, @ctx.reset_func) { precond.call unless precond.nil? } rescue next
        postcond.call(res)
      }
      return ast if test_outputs.all?
    }
    raise RuntimeError, "No candidates found"
  end
end
