require 'unparser'

class Synthesizer
  include AST

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

  def fn_args
    min_args = @inputs.map(&:length).min
    max_args = @inputs.map(&:length).max
    raise NotImplementedError if min_args != max_args
    args = Array.new(min_args) { |i| s(:arg, "arg#{i}".to_sym)}
    return s(:args, *args)
  end

  def generate
    Enumerator.new do |enum|
      fragments = [s(:true), s(:false)]
      fragments.each { |f|
        enum.yield s(:def, :fn, fn_args, f)
      }
    end
  end

  def run
    generate.each { |prog|
      fn = eval(Unparser.unparse(prog))
      outputs = @inputs.map { |i| fn(*i) }
      return prog if outputs == @outputs
    }
  end
end
