module AST
  def s(ttype, type, *children)
    TypedNode.new(ttype, type, *children)
  end

  def eval_ast(ctx, ast, arg, reset_fn, &precond)
    max_args = ctx.args.map { |arg| arg.size }.max
    DBUtils.reset
    reset_fn.call unless reset_fn.nil?
    precond.call unless precond.nil?
    klass = Class.new
    bind = klass.class_eval { binding }
    max_args.times { |i|
      bind.local_variable_set("arg#{i}".to_sym, arg[i])
    }
    bind.eval(Unparser.unparse(ast))
  end
end
