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

    update_types_pass = RefineTypesPass.new
    progconds = @ctx.preconds.zip(@ctx.args, @ctx.postconds).map { |precond, arg, postcond|
      env = LocalEnvironment.new
      prog_ref = env.add_expr(s(@ctx.functype.ret, :hole, 0, {variance: CONTRAVARIANT}))
      seed = ProgWrapper.new(@ctx, s(@ctx.functype.ret, :envref, prog_ref), env)
      seed.look_for(:type, @ctx.functype.ret)
      progs = generate(seed, [precond], [arg], [postcond], true)

      env = LocalEnvironment.new
      branch_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
      seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, branch_ref), env)
      seed.look_for(:type, RDL::Globals.types[:bool])
      branches = generate(seed, [precond], [arg], [TRUE_POSTCOND], true)
      progs.product(branches).map { |prog, branch|
        ProgTuple.new(@ctx, prog, update_types_pass.process(branch.to_ast), [precond], [arg]) }
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
          possible.map &:prune_branches
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
        res, klass = eval_ast(@ctx, ast, arg, precond) rescue next
        begin
          klass.instance_exec res, &postcond
        rescue AssertionError => e
          puts "TODO"
        rescue Exception
          nil
        end
      }

      return ast if test_outputs.all? true
    }
    raise RuntimeError, "No candidates found"
  end
end
