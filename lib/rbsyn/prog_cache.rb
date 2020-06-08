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
      begin
        res, klass = eval_ast(@ctx, prog.to_ast, precond)
      rescue RbSynError => err
        raise err
      rescue StandardError => err
        next
      end
      klass.instance_eval {
        @params = postcond.parameters.map &:last
      }
      begin
        return prog if klass.instance_exec res, &postcond
      rescue RbSynError => err
        raise err
      rescue StandardError => err
        next
      end
    }
    nil
  end
end
