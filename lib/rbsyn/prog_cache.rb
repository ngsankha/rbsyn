class ProgCache
  include AST

  def initialize(ctx)
    @cache = Set.new
    @ctx = ctx
  end

  def add(prog)
    @cache.add(prog)
  end

  def find_prog(precond, postcond)
    @cache.each { |prog|
      res, klass = eval_ast(@ctx, prog.to_ast, precond) rescue next
      klass.instance_eval {
        @params = postcond.parameters.map &:last
      }
      return prog if klass.instance_exec res, &postcond rescue next
    }
    nil
  end
end
