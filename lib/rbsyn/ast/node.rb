class TypedNode < Parser::AST::Node
  # ttype: term type
  attr_reader :ttype

  def initialize(ttype, type, *children)
    @ttype = ttype
    super(type, children)
  end

  # This is monkey patched. See original source in ast gem
  def updated(type=nil, children=nil, properties=nil)
    new_type       = type       || @type
    new_children   = children   || @children
    new_properties = properties || {}

    if @type == new_type &&
        @children == new_children &&
        properties.nil?
      self
    else
      original_dup.send :initialize, @ttype, new_type, *new_children
    end
  end

  def update_ttype(ttype)
    original_dup.send :initialize, ttype, @type, *@children
  end
end
