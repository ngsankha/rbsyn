class EliminationStrategy
  def self.eliminate(progs)
    raise RuntimeError, "Not implemented"
  end
end

class DuplicateElimiation < EliminationStrategy
  def self.eliminate(progs)
    Set[*progs].to_a
  end
end

class MinSizeElimination < EliminationStrategy
  def self.eliminate(progs)
    least = progs.map { |prog| ProgSizePass.prog_size(prog.to_ast, nil) }.min
    progs.reject { |prog| ProgSizePass.prog_size(prog.to_ast, nil) > least }
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
