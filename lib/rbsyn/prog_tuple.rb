class ProgTuple
  include AST
  include SynHelper

  attr_reader :prog, :branch, :envs, :setups, :ctx

  def initialize(syn, prog, branch, envs, setups)
    if branch.is_a? BoolCond
      @branch = branch
    else
      raise RuntimeError, "expected branch condition to be a %bool" unless branch.type <= RDL::Globals.types[:bool]
      @branch = BoolCond.new
      @branch << branch
    end
    @ctx = syn
    @prog = prog
    @envs = envs
    @setups = setups
  end

  def eql?(other)
    return false unless other.is_a? ProgCond

    if @prog.is_a?(Array) && other.prog.is_a?(Array)
      @prog.all? { |prg| other.prog.include? prg }
    else
      @prog == other.prog
    end
  end

  def +(other)
    raise RuntimeError, "expected another ProgTuple" if other.class != self.class
    raise RuntimeError, "both progs should be of same type" if other.prog.type != @prog.type
    # TODO: how to merge when ProgCond are composed of multiple programs
    raise RuntimeError, "unimplemented" if other.prog.is_a?(Array) || @prog.is_a?(Array)
    merge_impl(self, other)
  end

  def to_ast
    if @prog.is_a? Array
      raise RuntimeError, "expected >1 subtrees" unless @prog.size > 1
      fragments = @prog.map(&:to_ast)
      branches = @prog.map { |program| program.branch }
      true_body = nil
      merged = nil
      fragments.zip(branches).each { |fragment, branch|
        if branch.true?
          if true_body.nil?
            true_body = fragment
          else
            raise RuntimeError, "expected only 1 true branch"
          end
        else
          if merged.nil?
            merged = s(:if, branch.to_ast, fragment)
          else
            merged = s(:if, branch.to_ast, fragment, merged)
          end
        end
      }
      unless true_body.nil?
        raise RuntimeError, "expected if" unless merged.type == :if
        merged = s(:if, *merged.children, true_body)
      end
      merged
    else
      @prog.expr
    end
  end

  def prune_branches
    if @prog.is_a? Array
      pruned_children = @prog.map { |prg| prg.prune_branches; prg }
      @prog = pruned_children
    end

    intermediate = self
    # BranchPruneStrategy.descendants.each { |strategy|
    #   intermediate = strategy.prune(intermediate)
    # }
    intermediate = BoolExprFold.prune(intermediate)
    intermediate = InverseBranchFold.prune(intermediate)
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
    "{ prog: #{progs}, branch: #{Unparser.unparse(@branch.to_ast)} }"
  end

  private
  # def make_or(first, second)
  #   raise RuntimeError, "expected parser nodes" unless first.is_a?(Parser::AST::Node) && second.is_a?(Parser::AST::Node)
  #   if first.type == :or
  #     children1 = first.children
  #   else
  #     children1 = [first]
  #   end

  #   if second.type == :or
  #     children2 = second.children
  #   else
  #     children2 = [second]
  #   end

  #   s(:or, *children1, *children2)
  # end

  # def equiv(first, second)
  #   raise "cannot handle both or now" if first.expr.type == :or && second.expr.type == :or
  #   first, second = second, first if second.expr.type == :or
  #   if first.expr.type == :or
  #     first.expr.children.include? second.expr
  #   else
  #     first == second
  #   end
  # end

  def merge_impl(first, second)
    if first.prog == second.prog && first.branch.implies(second.branch)
      return [ProgTuple.new(@ctx, first.prog, first.branch, [*first.envs, *second.envs], [*first.setups, *second.setups])]
    elsif first.prog == second.prog && !first.branch.implies(second.branch)
      new_cond = BoolCond.new
      new_cond << first.branch
      new_cond << second.branch
      return [ProgTuple.new(@ctx, first.prog, new_cond,
        [*first.envs, *second.envs], [*first.setups, *second.setups])]
    elsif first.prog != second.prog && !first.branch.implies(second.branch)
      new_cond = BoolCond.new
      new_cond << first.branch
      new_cond << second.branch
      return [ProgTuple.new(@ctx, [first, second], new_cond,
        [*first.envs, *second.envs], [*first.setups, *second.setups])]
    else
      # HACK: this is because synthesize is from a module, and needs @components variable
      # @components is available in Synthesizer class but not here.
      # TODO: refactor
      @components = @ctx.components
      @max_hash_size = @ctx.max_hash_size
      @max_depth = @ctx.max_depth
      # prog different branch same, need to discover a new path condition
      # TODO: make a function that returns the post cond for booleans
      output1 = (Array.new(first.envs.size, true) + Array.new(second.envs.size, false)).map { |item| Proc.new { |result| result == item }}
      bsyn1 = synthesize(@ctx.max_depth, RDL::Globals.types[:bool], [*first.envs, *second.envs], output1, [*first.setups, *second.setups], @ctx.reset_fn)
      output2 = (Array.new(first.envs.size, false) + Array.new(second.envs.size, true)).map { |item| Proc.new { |result| result == item }}
      bsyn2 = synthesize(@ctx.max_depth, RDL::Globals.types[:bool], [*first.envs, *second.envs], output2, [*first.setups, *second.setups], @ctx.reset_fn)
      tuples = []
      bsyn1.each { |b1|
        bsyn2.each { |b2|
          # puts "branch 1: #{b1}"
          # puts "branch 2: #{b2}"
          cond1 = BoolCond.new
          cond1 << b1
          cond2 = BoolCond.new
          cond2 << b2
          tuples << ProgTuple.new(@ctx, [ProgTuple.new(@ctx, first.prog, cond1, first.envs, first.setups),
            ProgTuple.new(@ctx, second.prog, cond2, second.envs, second.setups)],
            first.branch, [*first.envs, *second.envs], [*@setups, *second.setups])
        }
      }
      return tuples
    end
  end
end