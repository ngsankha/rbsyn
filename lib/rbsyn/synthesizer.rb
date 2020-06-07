COVARIANT = :+
CONTRAVARIANT = :-
TRUE_POSTCOND = Proc.new { |result| result == true }

class Synthesizer
  include AST
  include SynHelper
  include Utils

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
        @ctx.logger.debug("Synthesized program:\n#{format_ast(prog.to_ast)}")
      else
        @ctx.logger.debug("Found program in cache:\n#{format_ast(prog.to_ast)}")
      end

      env = LocalEnvironment.new
      branch_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
      seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, branch_ref), env)
      seed.look_for(:type, RDL::Globals.types[:bool])
      branches = generate(seed, [precond], [TRUE_POSTCOND], true)
      cond = BoolCond.new
      branches.each { |b| cond << update_types_pass.process(b.to_ast) }

      # puts Unparser.unparse(prog.to_ast)
      # puts Unparser.unparse(cond.to_ast)
      # puts "======"

      @ctx.logger.debug("Synthesized branch: #{format_ast(cond.to_ast)}")
      ProgTuple.new(@ctx, prog, cond, [precond], [postcond])
    }

    # if there is only one generated, there is nothing to merge, we return the first synthesized program
    return progconds[0].prog if progconds.size == 1

    # progconds = merge_same_progs(progconds).map { |progcond| [progcond] }
    progconds.map! { |progcond| [progcond] }

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

      ELIMINATION_ORDER.each { |strategy| results = strategy.eliminate(results) }
      results.sort { |a, b| flat_comparator(a, b) }
    }

    completed.each { |progcond|
      ast = progcond.to_ast
      test_outputs = @ctx.preconds.zip(@ctx.postconds).map { |precond, postcond|
        res, klass = eval_ast(@ctx, ast, precond) rescue next
        begin
          klass.instance_eval { @params = postcond.parameters.map &:last }
          klass.instance_exec res, &postcond
        rescue Exception => e
          # puts Unparser.unparse(ast)
          # puts e
          # puts e.backtrace
          nil
        end
      }

      return ast if test_outputs.all? true
    }
    raise RuntimeError, "No candidates found"
  end

  def flat_comparator(a, b)
    if ProgSizePass.prog_size(a.to_ast, nil) < ProgSizePass.prog_size(b.to_ast, nil)
      1
    elsif ProgSizePass.prog_size(a.to_ast, nil) == ProgSizePass.prog_size(b.to_ast, nil)
      0
    else
      -1
    end
  end
end
