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

  def change_effect_precision(level)
    RDL::Globals.info.info.each { |cls, cls_info|
      cls_info.each { |meth, attrs|
        attrs[:read] = attrs[:read].map { |r| changed_annotation(r, level) } if attrs.key? :read
        attrs[:write] = attrs[:write].map { |w| changed_annotation(w, level) } if attrs.key? :write
      }
    }
  end

  private
  def changed_annotation(annotation, level)
    case level
    when 0
      # leave as is
      return annotation
    when 1
      # reduce annotations to class level things
      if annotation.include? '.'
        return annotation.split('.').first
      else
        return annotation
      end
    when 2
      # reduce annotations to pure/impure
      if annotation == ''
        return ''
      else
        return '*'
      end
    else
      raise RbSynError, "Unexpected"
    end
  end
end
