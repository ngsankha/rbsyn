class EliminationStrategy
  def self.eliminate(progs)
    raise RuntimeError, "Not implemented"
  end
end

class BranchCountElimination < EliminationStrategy
  # only keeps programs with minimal number of branches
  def self.eliminate(progs)
    counts = progs.map { |prog| count_branches(prog) }
    min_count = counts.min
    selected_idx = counts.each_index.select{ |i| counts[i] == min_count }
    selected_progs = selected_idx.map { |idx| progs[idx] }
    return selected_progs
  end

  private
  def self.count_branches(prog)
    count = 1
    if prog.prog.is_a? Array
      RDL.type_cast(prog.prog, 'Array<ProgTuple>', force: true)
        .each { |subprog|
          count += count_branches(subprog)
      }
    end
    return count
  end
end

class DuplicateElimiation < EliminationStrategy
  def self.eliminate(progs)
    Set[*progs].to_a
  end
end

class TestElimination < EliminationStrategy
  extend AST

  def self.eliminate(progs)
    progs.select { |prog|
      ast = prog.to_ast
      prog.preconds.zip(prog.postconds).all? { |precond, postcond|
        begin
          res, klass = eval_ast(prog.ctx, ast, precond)
          klass.instance_eval { @params = postcond.parameters.map &:last }
          result = klass.instance_exec res, &postcond
          true
        rescue
          false
        end
      }
    }
  end
end
