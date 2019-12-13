class TypedNode < Parser::AST::Node
  # ttype: term type
  attr_reader :ttype

  def initialize(ttype, type, *children)
    @ttype = ttype
    super(type, children)
  end
end
