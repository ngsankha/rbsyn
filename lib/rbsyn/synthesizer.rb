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
    prog_cache = ProgCache.new @ctx

    update_types_pass = RefineTypesPass.new
    progconds = @ctx.preconds.zip(@ctx.postconds).map { |precond, postcond|
      prog = prog_cache.find_prog([precond], [postcond])
      if prog.nil?
        env = LocalEnvironment.new
        prog_ref = env.add_expr(s(@ctx.functype.ret, :hole, 0, {variance: CONTRAVARIANT}))
        seed = ProgWrapper.new(@ctx, s(@ctx.functype.ret, :envref, prog_ref), env)
        seed.look_for(:type, @ctx.functype.ret)
        prog = generate(seed, [precond], [postcond], false)
        # add to cache for future use
        prog_cache.add(prog)
      end

      env = LocalEnvironment.new
      branch_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
      seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, branch_ref), env)
      seed.look_for(:type, RDL::Globals.types[:bool])
      branches = generate(seed, [precond], [TRUE_POSTCOND], true)
      cond = BoolCond.new
      branches.each { |b| cond << update_types_pass.process(b.to_ast) }

      ProgTuple.new(@ctx, prog, cond, [precond])
    }

    # if there is only one generated, there is nothing to merge, we return the first synthesized program
    return progconds[0].prog if progconds.size == 1

    progconds = merge_same_progs(progconds).map { |progcond| [progcond] }

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
      results = BranchCountElimination.eliminate(results)
      # TODO: Duplicate elimination doesn't work
      results = DuplicateElimiation.eliminate(results)
      results
    }

    completed.each { |progcond|
      ast = progcond.to_ast
      test_outputs = @ctx.preconds.zip(@ctx.postconds).map { |precond, postcond|
        res, klass = eval_ast(@ctx, ast, precond) rescue next
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

  def merge_same_progs(progconds)
    merged = []
    progconds.each { |progcond|
      looked = merged.find { |processed| processed.prog.to_ast == progcond.prog.to_ast }
      unless looked.nil?
        progcond.branch.conds.each { |b| looked.branch << b }
        looked.preconds.push(*progcond.preconds)
      else
        merged << progcond
      end
    }
    merged
  end
end
