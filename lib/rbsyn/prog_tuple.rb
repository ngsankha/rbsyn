class ProgTuple
  include AST

  attr_reader :prog, :branch, :inputs, :setups

  def initialize(prog, branch, inputs, setups)
    @prog = prog
    @branch = branch
    @inputs = inputs
    @setups = setups
  end

  def +(other)
    raise RuntimeError, "expected another ProgTuple" if other.class != self.class
    if @prog == other.prog && @branch == other.branch
      return ProgTuple.new(@prog, @branch, [*@inputs, *other.inputs], [*@setups, *other.setups])
    elsif @prog == other.prog && @branch != other.branch
      return ProgTuple.new(@prog, s(:or, @branch, other.branch), [*@inputs, *other.inputs], [*@setups, *other.setups])
    elsif @prog != other.prog && @branch != other.branch
      return ProgTuple.new(s(:if, @branch, @prog, s(:if, other.branch, other.prog)),
        s(:or, @branch, other.branch), [*@inputs, *other.inputs], [*@setups, *other.setups])
    else
      # when both are different, need to discover a new path condition
      
    end
  end
end