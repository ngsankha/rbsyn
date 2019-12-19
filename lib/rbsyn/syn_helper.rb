module SynHelper
  include TypeOperations

  def generate(seed_hole, preconds, args, postconds, return_all=false)
    correct_progs = []

    is_pc = seed_hole.children[2]

    work_list = [seed_hole]
    until work_list.empty?
      ast = work_list.shift
      pass1 = ExpandHolePass.new @ctx
      expanded = pass1.process(ast)
      expand_map = pass1.expand_map.map { |i| i.times.to_a }
      generated_asts = expand_map[0].product(*expand_map[1..]).map { |selection|
        pass2 = ExtractASTPass.new(selection)
        pass2.process(expanded)
      }
      evaluable = generated_asts.reject { |ast| NoHolePass.has_hole? ast }
      evaluable.each { |ast|
        test_outputs = preconds.zip(args, postconds).map { |precond, arg, postcond|
          res = eval_ast(@ctx, ast, arg, @ctx.reset_func) { precond.call unless precond.nil? } rescue next
          postcond.call(res)
        }

        if test_outputs.all?
          correct_progs << ast
          return ast unless return_all
        end
      }

      remainder_holes = generated_asts.select { |ast| NoHolePass.has_hole? ast }

      # Note: Invariant here is that the last candidate in the work list is
      # always a just hole, with next possible call chain length. If the
      # work_list is empty and we have all correct programs that means we have
      # all correct programs up that length
      if work_list.empty? && !correct_progs.empty? && return_all
        return correct_progs
      end

      work_list = [*remainder_holes, *work_list]
    end
    raise RuntimeError, "No candidates found"
  end
end
