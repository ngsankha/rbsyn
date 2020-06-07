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
