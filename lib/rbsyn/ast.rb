module AST
  def s(ttype, type, *children)
    TypedNode.new(ttype, type, *children)
  end

  def eval_ast(ctx, ast, arg, precond)
    max_args = ctx.args.map { |arg| arg.size }.max
    klass = Class.new
    klass.instance_eval {
      @count = 0
      @passed_count = 0
      @ctx = ctx
      extend Assertions
    }
    bind = klass.instance_eval { binding }
    DBUtils.reset
    ctx.reset_func.call unless ctx.reset_func.nil?
    klass.instance_eval &precond unless precond.nil?
    max_args.times { |i|
      bind.local_variable_set("arg#{i}".to_sym, arg[i])
    }
    puts Unparser.unparse(ast)
    result = bind.eval(Unparser.unparse(ast))
    [result, klass]
  end
end
