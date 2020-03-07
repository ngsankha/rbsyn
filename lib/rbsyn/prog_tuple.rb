class ProgTuple
  include AST
  include SynHelper

  attr_reader :ctx, :branch, :preconds, :postconds
  attr_accessor :prog

  def initialize(ctx, prog, branch, preconds, postconds)
    @ctx = ctx
    if branch.is_a? BoolCond
      @branch = RDL.type_cast(branch, 'BoolCond')
    else
      raise RuntimeError, "expected a TypedNode" unless branch.is_a? TypedNode
      raise RuntimeError, "expected branch condition to be a %bool" unless RDL.type_cast(branch, 'TypedNode').ttype <= RDL::Globals.types[:bool]
      @branch = BoolCond.new
      @branch << RDL.type_cast(branch, 'TypedNode')
    end
    raise RuntimeError, "expected ProgWrapper" unless prog.is_a?(Array) || prog.is_a?(ProgWrapper)
    @prog = prog
    @preconds = preconds
    @postconds = postconds
  end

  def ==(other)
    eql? other
  end

  def eql?(other)
    hash == other.hash
  end

  def hash
    to_ast.hash
  end

  def +(other)
    raise RuntimeError, "expected another ProgTuple" if other.class != self.class

    if current_prog_passes?(other) && has_same_prog?(other) && guess_branch_same?(other)
      propagate_conds(other)
      [self]
    else
      merge_rec(self, other)
    end
  end

  def guess_branch_same?(other)
    precond = other.preconds[0]
    postcond = other.postconds[0]
    res, klass = eval_ast(@ctx, @branch.to_ast, precond)
    res == true
  end

  def propagate_conds(other)
    if current_prog_passes? other
      if @prog.is_a? Array
        if @prog[0].current_prog_passes? other
          @prog[0].propagate_conds other
        elsif @prog[1].current_prog_passes? other
          @prog[1].propagate_conds other
        else
          raise RuntimeError, "unexpected"
        end
      end
      other.branch.conds.each { |b| @branch << b }
      @preconds.push(*other.preconds)
      @postconds.push(*other.postconds)
    end
  end

  def has_same_prog?(other)
    if @prog.is_a? ProgWrapper
      @prog == other.prog
    else
      @prog.any? { |prog| prog.has_same_prog? other }
    end
  end

  def current_prog_passes?(other)
    other.preconds.zip(other.postconds).all? { |precond, postcond|
      begin
        res, klass = eval_ast(other.ctx, to_ast, precond)
        klass.instance_eval { @params = postcond.parameters.map &:last }
        result = klass.instance_exec res, &postcond
        true
      rescue
        false
      end
    }
  end

  def to_ast
    if @prog.is_a? Array
      prog_cast = RDL.type_cast(@prog, 'Array<ProgTuple>', force: true)
      raise RuntimeError, "expected <3 subtrees" unless prog_cast.size < 3
      fragments = prog_cast.map { |t| t.to_ast }
      branches = prog_cast.map { |program| program.branch }

      if prog_cast.size == 1
        prog_cast[0].to_ast
      else
        if branches[0].inverse?(branches[1])
          s(fragments[0].ttype, :if, branches[0].to_ast, fragments[0], fragments[1])
        else
          s(fragments[0].ttype, :if, branches[0].to_ast, fragments[0],
            s(fragments[1].ttype, :if, branches[1].to_ast, fragments[1]))
        end
      end
    else
      RDL.type_cast(@prog, 'ProgWrapper').to_ast
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

  def clone
    ProgTuple.new(@ctx, @prog.dup, @branch.dup, @preconds.dup, @postconds.dup)
  end

  private
  def merge_rec(first, second)
    raise RuntimeError, "second should be a single prog" if second.prog.is_a? Array
    merged = RDL.type_cast([], 'Array<ProgTuple>', force: true)
    if first.prog.is_a? Array
      RDL.type_cast(first.prog, 'Array<ProgTuple>', force: true).each_with_index { |fprog, i|
        merged_subprogs = merge_rec(fprog, second)
        merged_subprogs.each { |m|
          fdup = first.clone
          RDL.type_cast(fdup.prog, 'Array<ProgTuple>', force: true)[i] = m
          merged << fdup
        }
      }
    end
    merged.push(*merge_impl(first, second))
    return merged
  end

  def merge_impl(first, second)
    if first.prog == second.prog && first.branch.implies(second.branch)
      return [ProgTuple.new(@ctx, first.prog, first.branch, [*first.preconds, *second.preconds], [*first.postconds, *second.postconds])]
    elsif first.prog == second.prog && !first.branch.implies(second.branch)
      new_cond = BoolCond.new
      new_cond << first.branch.to_ast
      new_cond << second.branch.to_ast
      return [ProgTuple.new(@ctx, first.prog, new_cond,
        [*first.preconds, *second.preconds],
        [*first.postconds, *second.postconds])]
    elsif first.prog != second.prog && !first.branch.implies(second.branch)
      new_cond = BoolCond.new
      new_cond << first.branch.to_ast
      new_cond << second.branch.to_ast
      return [ProgTuple.new(@ctx, [first, second], new_cond,
        [*first.preconds, *second.preconds],
        [*first.postconds, *second.postconds])]
    else
      # prog different branch same, need to discover a new path condition
      # TODO: make a function that returns the post cond for booleans
      output1 = (Array.new(first.preconds.size, true) + Array.new(second.preconds.size, false)).map { |item|
        Proc.new { |result| RDL.type_cast(result, '%bool') == item } }
      env = LocalEnvironment.new
      b1_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
      seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, b1_ref), env)
      seed.look_for(:type, RDL::Globals.types[:bool])
      bsyn1 = generate(seed, [*first.preconds, *second.preconds], output1, true)

      output2 = (Array.new(first.preconds.size, false) + Array.new(second.preconds.size, true)).map { |item|
        Proc.new { |result| RDL.type_cast(result, '%bool', force: true) == item }}
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

      tuples = RDL.type_cast([], 'Array<ProgTuple>', force: true)
      bsyn1.each { |b1|
        bsyn2.each { |b2|
          cond1 = BoolCond.new
          cond1 << b1.to_ast
          cond2 = BoolCond.new
          cond2 << b2.to_ast
          tuples << ProgTuple.new(@ctx, [ProgTuple.new(@ctx, first.prog, cond1, first.preconds, first.postconds),
            ProgTuple.new(@ctx, second.prog, cond2, second.preconds, second.postconds)],
            first.branch, [*first.preconds, *second.preconds], [*first.postconds, *second.postconds])
        }
      }
      return tuples
    end
  end

  def speculate_opposite_branch(branches, preconds, postconds)
    guessed = branches.map { |b|
      if b.to_ast.type == :send && b.to_ast.children[1] == :!
        b.to_ast.children[0]
      else
        s(RDL::Globals.types[:bool], :send, b.to_ast, :!)
      end
    }
    guessed.select{ |b|
      preconds.zip(postconds).map { |items|
        items_cast = RDL.type_cast(items, '[Proc, Proc]')
        precond = items_cast[0]
        postcond = items_cast[1]
        res, klass = eval_ast(@ctx, b.to_ast, precond) rescue next
        klass.instance_exec(res, &postcond)
      }.all?
    }
  end
end
