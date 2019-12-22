module AST
  def s(ttype, type, *children)
    TypedNode.new(ttype, type, *children)
  end

  def eval_ast(ctx, ast, arg, reset_fn, &precond)
    max_args = ctx.args.map { |arg| arg.size }.max
    klass = Class.new
    bind = klass.instance_eval { binding }
    DBUtils.reset
    reset_fn.call unless reset_fn.nil?
    klass.instance_eval &precond unless precond.nil?
    max_args.times { |i|
      bind.local_variable_set("arg#{i}".to_sym, arg[i])
    }
    result = bind.eval(Unparser.unparse(ast))
    [result, klass]
  end
end
