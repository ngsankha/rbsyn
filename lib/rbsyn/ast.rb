module AST
  def s(ttype, type, *children)
    TypedNode.new(ttype, type, *children)
  end

  def eval_ast(ctx, ast, precond)
    max_args = ctx.functype.args.size
    args = max_args.times.map { |i| "arg#{i}".to_sym }
    klass = Class.new
    klass.instance_eval {
      @count = 0
      @passed_count = 0
      @ctx = ctx
      extend Assertions
    }
    bind = klass.instance_eval { binding }
    @ctx.curr_binding = bind
    DBUtils.reset
    ctx.reset_func.call unless ctx.reset_func.nil?
    func = s(@ctx.functype, :def, @ctx.mth_name,
      s(RDL::Globals.types[:top], :args, *args.map { |arg|
        s(RDL::Globals.types[:top], :arg, arg)
      }), ast)
    # puts Unparser.unparse(func)
    klass.instance_eval Unparser.unparse(func)
    result = klass.instance_eval &precond unless precond.nil?
    [result, klass]
  end
end
