class ProgWrapper
  include AST

  attr_reader :seed, :env, :exprs
  attr_accessor :passed_asserts

  def initialize(ctx, seed, env, exprs=[])
    @ctx = ctx
    @seed = seed
    @env = env
    @exprs = exprs
    @passed_asserts = 0
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
    pass = FlattenProgramPass.new(@env)
    ast = pass.process(@seed)
    return ast if @exprs.empty?

    effect_exprs = @exprs.map { |e| pass.process(e) }
    assigns = var_expr.map { |id, e|
      s(RDL::Globals.type[:top], :lvasgn, "#{VAR_PREFIX}#{id}".to_sym, e)
    }

    final = s(ast.ttype, :begin, *[
      *assigns,
      *ast,
      *effect_exprs
    ])
    final
  end

  def ==(other)
    to_ast == other.to_ast
  end

  def add_side_effect_expr(expr)
    @exprs << expr
  end

  def build_candidates
    update_types_pass = RefineTypesPass.new
    case @looking_for
    when :type
      pass1 = ExpandHolePass.new(@ctx, @env)
      if @exprs.empty?
        # no side effected expressions yet
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
      else
        puts "I am here"
        # we are filling a side effect expression
        expanded = pass1.process(@exprs.last)
        expand_map = pass1.expand_map.map { |i| i.times.to_a }
        generated_asts = expand_map[0].product(*expand_map[1..]).map { |selection|
          pass2 = ExtractASTPass.new(selection, @env)
          program = update_types_pass.process(pass2.process(expanded))
          new_env = pass2.env
          new_exprs = @exprs.dup
          new_exprs[-1] = program
          prog_wrap = ProgWrapper.new(@ctx, program, new_env, new_exprs)
          prog_wrap.look_for(:type, @target)
          prog_wrap
        }
      end
    when :effect
      # TODO: ordering can be done better to build candidates programs with
      # method calls that can satisfy multiple effects at once
      @target.map { |eff|
        methds = methods_with_write_effect(eff)
        eff_hole = s(RDL::Globals.types[:top], :hole, 1, {effect: true})
        pass1 = ExpandHolePass.new(@ctx, @env)
        pass1.effect_methds = methds
        expanded = pass1.process(eff_hole)
        expand_map = pass1.expand_map.map { |i| i.times.to_a }
        generated_asts = expand_map[0].product(*expand_map[1..]).map { |selection|
          pass2 = ExtractASTPass.new(selection, @env)
          program = update_types_pass.process(pass2.process(expanded))
          new_env = pass2.env
          prog_wrap = ProgWrapper.new(@ctx, @seed, new_env, @exprs.dup)
          prog_wrap.add_side_effect_expr(program)
          prog_wrap.look_for(:type, RDL::Globals.types[:top])
          prog_wrap
        }
      }.flatten
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
    [@seed, *@exprs].any? { |prog| NoHolePass.has_hole? prog, @env }
  end

  def prog_size
    [@seed, *@exprs].map { |prog| ProgSizePass.prog_size prog, @env }.sum
  end

  def ttype
    @seed.ttype
  end
end