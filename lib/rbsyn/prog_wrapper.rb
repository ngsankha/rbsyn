class ProgWrapper
  attr_reader :seed, :env

  def initialize(ctx, seed, env)
    @ctx = ctx
    @seed = seed
    @env = env
  end

  def look_for(kind, target)
    case kind
    when :type
      raise RuntimeError, "expected target to be a type" unless target.is_a? RDL::Type::Type
      @looking_for = :type
      @target = target
    when :effect
      @looking_for = :effect
      @target = target
    else
      raise RuntimeError, "can look for types/effects only"
    end
  end

  def to_ast
    @seed
  end

  def ==(other)
    @seed == other.seed
  end

  def build_candidates
    update_types_pass = RefineTypesPass.new
    case @looking_for
    when :type
      pass1 = ExpandHolePass.new(@ctx, @env)
      expanded = pass1.process(@seed)
      expand_map = pass1.expand_map.map { |i| i.times.to_a }
      generated_asts = expand_map[0].product(*expand_map[1..]).map { |selection|
        pass2 = ExtractASTPass.new(selection, @env)
        program = update_types_pass.process(pass2.process(expanded))
        new_env = pass2.env
        prog_wrap = ProgWrapper.new(@ctx, program, new_env)
        prog_wrap.look_for(:type, @target)
        prog_wrap
      }
    when :effect
      @target.each { |eff|
        cls = eff[0]
        field = eff[1]
        if cls == AnotherUser && field == :id
          methds = methods_with_write_effect(eff)
          raise RuntimeError, "TODO"
        end
      }
    else
      raise RuntimeError, "can look for types/effects only"
    end
  end

  def methods_with_write_effect(eff)
    if eff.size == 1
      raise RuntimeError, "TODO"
    elsif eff.size == 2
      klass = eff[0]
      field = eff[1]
      effect_causing = []
      # TODO: take care between nominal and singleton types
      # right now singleton types are not being handled
      RDL::Globals.info.info.each { |cls, v1|
        v1.each { |meth, v2|
          v2.fetch(:write, []).each { |weff|
            effect_causing << [cls, meth] if (weff[0] == klass && weff[1] == field)
          }
        }
      }
      return effect_causing
    else
      raise RuntimeError, "don't know how to handle"
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