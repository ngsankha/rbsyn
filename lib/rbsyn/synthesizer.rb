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
        interp(expr)
      end
    }
    return nil if p.size == 0

    case p[0]
    when :true
      return true
    when :false
      return false
    when :where, :exists?
      cls = p[1]
      args = p[2..]
      return cls.send(p[0], *args)
    when :arg
      # [:arg, input_id]
      return input[p[1]]
    else
      raise NotImplementedError
    end
  end

  def run
    @choices.each { |choice|
      program = []
      case choice
      when :true
        program = [:true]
      when :false
        program = [:false]
      when :where
      when :exists?
      else
        raise NotImplementedError
      end

      checked = true
      @inputs.zip(@outputs).each { |i, o|
        result = interp(program, i)
        checked = checked && (result == o)
      }
      return program if checked
    }
    raise "Failed to find program"
  end
end
