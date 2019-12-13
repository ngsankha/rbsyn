class ExpandHolePass < ::AST::Processor
  include AST

  attr_reader :expand_map

  def initialize(ctx)
    @expand_map = []
    @ctx = ctx
  end

  def on_hole(node)
    expanded = []

    # synthesize boolean constants
    if node.ttype <= RDL::Globals.types[:bool]
      expanded.concat bool_const
    end

    # synthesize variables in the environment
    expanded.concat lvar(node.ttype, @ctx.tenv)

    @expand_map << expanded.size
    s(node.ttype, :filled_hole, *expanded)
  end

  def handler_missing(node)
    if k.is_a?(TypedNode) && k.type == :hole
      process(k)
    else
      k
    end
  end

  private
  def bool_const
    [TypedNode.new(RDL::Globals.types[:true], :true),
    TypedNode.new(RDL::Globals.types[:false], :false)]
  end

  def lvar(type, tenv)
    tenv.select { |k, v| v <= type }
      .map { |k, v| TypedNode.new(type, :lvar, k) }
  end
end
