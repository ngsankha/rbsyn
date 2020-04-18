require 'rouge'

module Utils
  def format(prog)
    formatter = Rouge::Formatters::Terminal256.new
    lexer = Rouge::Lexers::Ruby.new
    formatter.format(lexer.lex(prog))
  end

  def format_ast(ast)
    format(Unparser.unparse(ast))
  end
end
