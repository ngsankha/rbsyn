require 'parser/current'

module AST
  def s(type, *children)
    Parser::AST::Node.new(type, children)
  end
end