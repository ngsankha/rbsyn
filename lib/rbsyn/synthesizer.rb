COVARIANT = :+
CONTRAVARIANT = :-
TRUE_POSTCOND = Proc.new { |result| result == true }

class Synthesizer
  include AST

  def initialize(ctx)
    @ctx = ctx
  end

  def run
    @ctx.load_tenv!
    work_list = [s(@ctx.functype.ret, :hole)]
    new_work_list = []
    work_list.each { |ast|
      pass1 = ExpandHolePass.new @ctx
      expanded = pass1.process(ast)
      expand_map = pass1.expand_map.map { |i| i.times.to_a }
      generated_asts = expand_map[0].product(*expand_map[1..]).map { |selection|
        pass2 = ExtractASTPass.new(selection)
        pass2.process(expanded)
      }
      evaluable = generated_asts.reject { |ast| NoHolePass.has_hole? ast }
      evaluable.each { |ast|
        test_outputs = @ctx.preconds.zip(@ctx.args, @ctx.postconds).map { |precond, arg, postcond|
          res = eval_ast(@ctx, ast, arg, @ctx.reset_func) { precond.call unless precond.nil? } #rescue next
          postcond.call(res)
        }
        return ast if test_outputs.all?
      }

      remainder_holes = generated_asts.select { |ast| NoHolePass.has_hole? ast }
      new_work_list.concat(remainder_holes)
    }
    raise RuntimeError, "No candidates found"
  end
end
