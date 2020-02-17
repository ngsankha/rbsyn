class ProgTuple
  include AST
  include SynHelper

  attr_reader :ctx, :branch, :prog, :preconds

  def initialize(ctx, prog, branch, preconds)
    @ctx = ctx
    if branch.is_a? BoolCond
      @branch = branch
    else
      raise RuntimeError, "expected a TypedNode" unless branch.is_a? TypedNode
      raise RuntimeError, "expected branch condition to be a %bool" unless branch.ttype <= RDL::Globals.types[:bool]
      @branch = BoolCond.new
      @branch << branch.to_ast
    end
    raise RuntimeError, "expected ProgWrapper" unless prog.is_a?(Array) || prog.is_a?(ProgWrapper)
    @prog = prog
    @preconds = preconds
  end

  def ==(other)
    return false unless other.is_a? ProgTuple

    if @prog.is_a?(Array) && other.prog.is_a?(Array)
      @prog.all? { |prg| other.prog.include? prg }
    else
      @prog == other.prog
    end
  end

  def eql?(other)
    hash == other.hash
  end

  def hash
    to_ast.hash
  end

  def +(other)
    raise RuntimeError, "expected another ProgTuple" if other.class != self.class

    if other.prog.is_a?(Array) || @prog.is_a?(Array)
      first = if @prog.is_a? Array
        @prog
      else
        [@prog]
      end

      second = if other.prog.is_a? Array
        other.prog
      else
        [other.prog]
      end

      return first.product(second).map { |f, s| f + s }.flatten
    end

    raise RuntimeError, "both progs should be of same type" if other.prog.ttype != @prog.ttype

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
            merged = s(fragment.ttype, :if, branch.to_ast, fragment)
          else
            merged = s(fragment.ttype, :if, branch.to_ast, fragment, merged)
          end
        end
      }
      unless true_body.nil?
        raise RuntimeError, "expected if" unless merged.type == :if
        merged = s(:if, *merged.children, true_body)
      end
      merged
    else
      @prog.to_ast
    end
  end

  def prune_branches
    if @prog.is_a? Array
      pruned_children = @prog.map { |prg| prg.prune_branches; prg }
      @prog = pruned_children
    end

    intermediate = self
    # puts intermediate
    # TODO: ordering
    # BranchPruneStrategy.descendants.each { |strategy|
    #   intermediate = strategy.prune(intermediate)
    # }
    intermediate = SpeculativeInverseBranchFold.prune(intermediate)
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
      progs = Unparser.unparse(@prog.to_ast)
    end
    "{ prog: #{progs}, branch: #{Unparser.unparse(@branch.to_ast)} }"
  end

  private
  def merge_impl(first, second)
    if first.prog == second.prog && first.branch.implies(second.branch)
      return [ProgTuple.new(@ctx, first.prog, first.branch, [*first.preconds, *second.preconds])]
    elsif first.prog == second.prog && !first.branch.implies(second.branch)
      new_cond = BoolCond.new
      new_cond << first.branch.to_ast
      new_cond << second.branch.to_ast
      return [ProgTuple.new(@ctx, first.prog, new_cond,
        [*first.preconds, *second.preconds])]
    elsif first.prog != second.prog && !first.branch.implies(second.branch)
      new_cond = BoolCond.new
      new_cond << first.branch.to_ast
      new_cond << second.branch.to_ast
      return [ProgTuple.new(@ctx, [first, second], new_cond,
        [*first.preconds, *second.preconds])]
    else
      # prog different branch same, need to discover a new path condition
      # TODO: make a function that returns the post cond for booleans
      output1 = (Array.new(first.preconds.size, true) + Array.new(second.preconds.size, false)).map { |item| Proc.new { |result| result == item }}
      env = LocalEnvironment.new
      b1_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
      seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, b1_ref), env)
      seed.look_for(:type, RDL::Globals.types[:bool])
      bsyn1 = generate(seed, [*first.preconds, *second.preconds], output1, true)

      output2 = (Array.new(first.preconds.size, false) + Array.new(second.preconds.size, true)).map { |item| Proc.new { |result| result == item }}
      opp_branch = speculate_opposite_branch(bsyn1, [*first.preconds, *second.preconds], output2)
      unless opp_branch.empty?
        bsyn2 = opp_branch
      else
        env = LocalEnvironment.new
        b2_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
        seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, b2_ref), env)
        seed.look_for(:type, RDL::Globals.types[:bool])
        bsyn2 = generate(seed, [*first.preconds, *second.preconds], output2, true)
      end

      tuples = []
      bsyn1.each { |b1|
        bsyn2.each { |b2|
          cond1 = BoolCond.new
          cond1 << b1.to_ast
          cond2 = BoolCond.new
          cond2 << b2.to_ast
          tuples << ProgTuple.new(@ctx, [ProgTuple.new(@ctx, first.prog, cond1, first.preconds),
            ProgTuple.new(@ctx, second.prog, cond2, second.preconds)],
            first.branch, [*first.preconds, *second.preconds])
        }
      }
      return tuples
    end
  end

  def speculate_opposite_branch(branches, preconds, postconds)
    guessed = branches.map { |b|
      if b.to_ast.type == :send && b.to_ast.children[1] == :!
        ProgWrapper.new(@ctx, b.to_ast.children[0], b.env)
      else
        ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :send, b.seed, :!), b.env)
      end
    }
    guessed.select{ |b|
      preconds.zip(postconds).map { |precond, postcond|
        res, klass = eval_ast(@ctx, b.to_ast, precond) rescue next
        klass.instance_exec res, &postcond
      }.all?
    }
  end
end
