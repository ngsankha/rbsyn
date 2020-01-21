class ProgWrapper

  def initialize(ctx, seed)
    @ctx = ctx
    @seed = seed
  end

  def look_for(kind, target)
    case kind
    when :type
      raise RuntimeError, "expected target to be a type" unless target.is_a? RDL::Type::Type
      @looking_for = :type
      @target = target
    when :effect
      raise RuntimeError, "TODO"
    else
      raise RuntimeError, "can look for types/effects only"
    end
  end

  def to_ast
    @seed
  end

  def eql?(other)
    @seed = other.seed
  end

  def build_candidates
    case @looking_for
    when :type
      pass1 = ExpandHolePass.new @ctx
      expanded = pass1.process(@seed)
      expand_map = pass1.expand_map.map { |i| i.times.to_a }
      generated_asts = expand_map[0].product(*expand_map[1..]).map { |selection|
        pass2 = ExtractASTPass.new(selection)
        prog_wrap = ProgWrapper.new(@ctx, pass2.process(expanded))
        prog_wrap.look_for(:type, @target)
        prog_wrap
      }
    when :effect
      raise RuntimeError, "TODO"
    else
      raise RuntimeError, "can look for types/effects only"
    end
  end

  def has_hole?
    NoHolePass.has_hole? to_ast
  end

  def prog_size
    ProgSizePass.prog_size to_ast
  end

  def ttype
    @seed.ttype
  end
end