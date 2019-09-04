
class Synthesizer

  def initialize
    @states = []
    @inputs = []
    @outputs = []
    @choices = [:true, :false, :where, :exists?]
  end

  def add_example(input, output)
    # Marshal.load(Marshal.dump(o)) is an ugly way to clone objects
    @states << Marshal.load(Marshal.dump(Table.db))
    @inputs << input
    @outputs << output
  end

  def interp(p, input)
    p.map { |expr|
      if expr.is_a? Array
        interp(expr, input)
      end
    }
    return nil if p.size == 0

    case p[0]
    when :true
      return true
    when :false
      return false
    else
      raise NotImplementedError
    end
  end

  def generate
    Enumerator.new do |enum|
      fragments = [:true, :false]
      fragments.each { |f|
        enum.yield [f]
      }
    end
  end

  def run
    generate.each { |prog|
      outputs = @inputs.map { |i| interp(prog, i)}
      return prog if outputs == @outputs
    }
  end
end
