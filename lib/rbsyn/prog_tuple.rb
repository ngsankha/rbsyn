class ProgTuple
  include AST
  include SynHelper

  attr_reader :prog, :branch, :envs, :setups

  def initialize(prog, branch, envs, setups)
    raise RuntimeError, "expected branch condition to be a %bool" unless branch.type <= RDL::Globals.types[:bool]
    @prog = prog
    @branch = branch
    @envs = envs
    @setups = setups
  end

  def +(other)
    raise RuntimeError, "expected another ProgTuple" if other.class != self.class
    raise RuntimeError, "both progs should be of same type" if other.prog.type != @prog.type
    # TODO: how to merge when ProgCond are composed of multiple programs
    raise RuntimeError, "unimplemented" if other.prog.is_a?(Array) || @prog.is_a?(Array)
    merge_impl(self, other)
  end

  def prune_branches
    strategies = BranchPruneStrategy.descendants
    if @prog.is_a? Array
      pruned_children = @prog.map { |prg| prg.prune_branches; prg }
      @prog = pruned_children
    end

    intermediate = self
    strategies.each { |strategy|
      intermediate = strategy.prune(intermediate)
    }
    @prog = intermediate.prog
    @branch = intermediate.branch
    # the setups and envs stay the same, so not copying them
  end

  def to_s
    if @prog.is_a? Array
      progs = "[#{@prog.map { |prog| prog.to_s }.join(", ")}]"
    else
      progs = Unparser.unparse(@prog.expr)
    end
    "{ prog: #{progs}, branch: #{Unparser.unparse(@branch.expr)} }"
  end

  private
  def merge_impl(first, second)
    # TODO: parameterize search depth in the synthesize call here
    if first.prog == second.prog && first.branch == second.branch
      return ProgTuple.new(first.prog, first.branch, [*first.envs, *second.envs], [*first.setups, *second.setups])
    elsif first.prog == second.prog && first.branch != second.branch
      return ProgTuple.new(first.prog,
        TypedAST.new(RDL::Globals.types[:bool], s(:or, first.branch.expr, second.branch.expr)),
        [*first.envs, *second.envs], [*first.setups, *second.setups])
    elsif first.prog != second.prog && first.branch != second.branch
      return ProgTuple.new([first, second],
        TypedAST.new(RDL::Globals.types[:bool], s(:or, first.branch.expr, second.branch.expr)),
        [*first.envs, *second.envs], [*first.setups, *second.setups])
    else
      # prog different branch same, need to discover a new path condition
      output1 = Array.new(first.envs.size, true) + Array.size(second.envs.size, false)
      bsyn1 = synthesize(3, [*first.envs, *second.envs], output1, [*first.setups, *second.setups])
      output2 = Array.new(first.envs.size, false) + Array.size(second.envs.size, true)
      bsyn2 = synthesize(3, [*first.envs, *second.envs], output2, [*first.setups, *second.setups])
      return ProgTuple.new([ProgTuple.new(first.prog, bsyn1, first.envs, first.setups),
                            ProgTuple.new(second.prog, bsyn2, second.envs, second.setups)],
                            first.branch, [*first.envs, *second.envs], [*@setups, *second.setups])
    end
  end
end