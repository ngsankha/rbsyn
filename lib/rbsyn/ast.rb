class TypedAST
  attr_reader :type, :expr

  def initialize(type, expr)
    @type = type
    @expr = expr
  end

  def to_s
    "#{Unparser.unparse(@expr)} : #{@type}"
  end

  def ==(other)
    @expr == other.expr
  end
end

module AST
  def s(type, *children)
    Parser::AST::Node.new(type, children)
  end

  def eval_ast(ast, env, &setup)
    DBUtils.reset
    setup.call unless setup.nil?
    klass = Class.new
    bind = klass.class_eval { binding }
    env.bindings.each { |b|
      bind.local_variable_set(b, env[b].value)
    }
    bind.eval(Unparser.unparse(ast))
  end
end
