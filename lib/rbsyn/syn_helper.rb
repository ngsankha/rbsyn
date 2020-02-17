module SynHelper
  include TypeOperations

  def generate(seed_hole, preconds, postconds, return_all=false)
    correct_progs = []

    work_list = [seed_hole]
    until work_list.empty?
      base = work_list.shift
      effect_needed = []
      generated = base.build_candidates
      evaluable = generated.reject &:has_hole?

      evaluable.each { |prog_wrap|
        test_outputs = preconds.zip(postconds).map { |precond, postcond|
          res, klass = eval_ast(@ctx, prog_wrap.to_ast, precond) rescue next
          begin
            klass.instance_eval {
              @params = postcond.parameters.map &:last
            }
            klass.instance_exec res, &postcond
          rescue AssertionError => e
            prog_wrap.passed_asserts = e.passed_count
            prog_wrap.look_for(:effect, e.read_set)
            effect_needed << prog_wrap
          rescue Exception => e
            # puts e
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
      remainder_holes.push(*effect_needed)

      # Note: Invariant here is that the last candidate in the work list is
      # always a just hole, with next possible call chain length. If the
      # work_list is empty and we have all correct programs that means we have
      # all correct programs up that length
      if !correct_progs.empty? && return_all
        return correct_progs
      end

      work_list = [*work_list, *remainder_holes].sort { |a, b| comparator(a, b) }
    end
    raise RuntimeError, "No candidates found"
  end

  def comparator(a, b)
    if a.passed_asserts < b.passed_asserts
      1
    elsif a.passed_asserts == b.passed_asserts
      if a.prog_size < b.prog_size
        -1
      elsif a.prog_size == b.prog_size
        0
      else
        1
      end
    else
      -1
    end
  end
end
