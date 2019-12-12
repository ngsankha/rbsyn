class BoolCond
  include AST

  attr_reader :conds

  def initialize
    @conds = []
  end

  def <<(cond)
    raise RuntimeError, "expected TypedAST, got #{cond}" unless cond.is_a? TypedAST
    @conds << cond.expr
  end

  def positive?
    raise RuntimeError, "works for only 1 condition" if @conds.size > 1
    stripepd, nots = strip_not(@conds[0])
    nots % 2 == 0
  end

  def negative?
    !positive?
  end

  def to_ast
    if conds.size == 1
      conds[0]
    else
      s(:or, *conds)
    end
  end

  def true?
    @solver = MiniSat::Solver.new
    @intermediates = {}
    vars = bool_vars(@conds)
    vars.each { |var| @solver << [-var] }
    !@solver.satisfied?
  end

  def inverse?(other)
    @solver = MiniSat::Solver.new
    @intermediates = {}
    a = bool_vars(@conds)
    b = bool_vars(other.conds)
    @solver << a
    @solver << b
    !@solver.satisfied?
  end

  def implies(other)
    @solver = MiniSat::Solver.new
    @intermediates = {}
    # self => other means check !a || b
    a = bool_vars(@conds)
    b = bool_vars(other.conds)
    # MiniSAT's crude API means we have to juggle all sorts of booleans expressions
    # a is a list of boolean ORs, which we negate
    a_negated = a.map(&:-@)
    and_exprs = a_negated.map { |aneg| [aneg, *b] }
    and_exprs.each { |expr| @solver << expr }
    @solver.solve # returns model if implies otherwise false
  end

  private
  def bool_vars(conds)
    constructed = []
    conds.each { |cond|
      stripped, nots = strip_not cond
      negate = nots % 2 == 1
      unless @intermediates.key? stripped
        @intermediates[stripped] = MiniSat::Var.new @solver
      end
      var = @intermediates[stripped]
      if negate
        constructed << -var
      else
        constructed << var
      end
    }
    constructed
  end

  def strip_not(cond)
    if cond.type == :send && cond.children[1] == :!
      stripped, count = strip_not(cond.children[0])
      [stripped, count + 1]
    else
      [cond, 0]
    end
  end
end