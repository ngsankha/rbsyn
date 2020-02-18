class ProgTuple
  include AST
  include SynHelper

  attr_reader :ctx, :branch, :prog, :preconds

  def initialize(ctx, prog, branch, preconds)
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

    if other.prog.is_a?(Array) || @prog.is_a?(Array)
      first = RDL.type_cast(if @prog.is_a? Array
        @prog
      else
        [@prog]
      end, 'Array<ProgTuple>')

      second = RDL.type_cast(if other.prog.is_a? Array
        other.prog
      else
        [other.prog]
      end, 'Array<ProgTuple>')

      return RDL.type_cast(first.product(second).map { |items| items[0] + items[1] }.flatten,
          'Array<ProgTuple>')
    end

    raise RuntimeError, "both progs should be of same type" if RDL.type_cast(other.prog, 'ProgWrapper')
      .ttype != RDL.type_cast(@prog, 'ProgWrapper').ttype

    merge_impl(self, other)
  end

  def to_ast
    if @prog.is_a? Array
      prog_cast = RDL.type_cast(@prog, 'Array<ProgTuple>')
      raise RuntimeError, "expected >1 subtrees" unless prog_cast.size > 1
      fragments = prog_cast.map { |t| t.to_ast }
      branches = prog_cast.map { |program| program.branch }
      true_body = nil
      merged = nil
      fragments.zip(branches).each { |items|
        items_cast = RDL.type_cast(items, '[TypedNode, BoolCond]')
        fragment = items_cast[0]
        branch = items_cast[1]
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
        merged = s(merged.ttype, :if, *[*merged.children, true_body])
      end
      merged
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
      output1 = (Array.new(first.preconds.size, true) + Array.new(second.preconds.size, false)).map { |item|
        Proc.new { |result| RDL.type_cast(result, '%bool') == item } }
      env = LocalEnvironment.new
      b1_ref = env.add_expr(s(RDL::Globals.types[:bool], :hole, 0, {bool_consts: false}))
      seed = ProgWrapper.new(@ctx, s(RDL::Globals.types[:bool], :envref, b1_ref), env)
      seed.look_for(:type, RDL::Globals.types[:bool])
      bsyn1 = generate(seed, [*first.preconds, *second.preconds], output1, true)

      output2 = (Array.new(first.preconds.size, false) + Array.new(second.preconds.size, true)).map { |item|
        Proc.new { |result| RDL.type_cast(result, '%bool') == item }}
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
