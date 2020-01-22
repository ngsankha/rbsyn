module SynHelper
  include TypeOperations

  def generate(seed_hole, preconds, args, postconds, return_all=false)
    correct_progs = []
    effect_needed = []

    work_list = [seed_hole]
    until work_list.empty?
      base = work_list.shift
      generated = base.build_candidates
      evaluable = generated.reject &:has_hole?

      evaluable.each { |prog_wrap|
        test_outputs = preconds.zip(args, postconds).map { |precond, arg, postcond|
          res, klass = eval_ast(@ctx, prog_wrap.to_ast, arg, precond) rescue next
          begin
            klass.instance_exec res, &postcond
          rescue AssertionError => e
            puts "TODO"
            # passed = klass.instance_eval { puts @count }
            read_set = e.read_set
            write_set = e.write_set
            # TODO: update prog wrap to set looking for
            # take care about size of the program
            effect_needed << prog_wrap
          rescue Exception
            next
          end
        }

        if test_outputs.all? true
          correct_progs << prog_wrap
          return prog_wrap unless return_all
        end
      }

      remainder_holes = generated.select { |prog_wrap|
        prog_wrap.has_hole? &&
        prog_wrap.prog_size <= @ctx.max_prog_size }

      # Note: Invariant here is that the last candidate in the work list is
      # always a just hole, with next possible call chain length. If the
      # work_list is empty and we have all correct programs that means we have
      # all correct programs up that length
      if !correct_progs.empty? && return_all
        return correct_progs
      end

      work_list = [*work_list, *remainder_holes]
    end
    raise RuntimeError, "No candidates found"
  end
end
