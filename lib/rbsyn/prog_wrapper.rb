class ProgWrapper
  include AST

  attr_reader :seed, :env, :exprs, :looking_for, :target
  attr_accessor :passed_asserts

  def initialize(ctx, seed, env, exprs=[])
    @ctx = ctx
    @seed = seed
    @env = env # LocalEnvironment
    @exprs = exprs
    @passed_asserts = 0
    @looking_for = :type
  end

  def look_for(kind, target)
    case kind
    when :type
      raise RbSynError, "expected target to be a type" unless target.is_a? RDL::Type::Type
      @looking_for = :type
      @target = target
    when :effect
      @looking_for = :effect
      @target = target
    when :teffect
      @looking_for = :teffect
      @target = target
    else
      raise RbSynError, "can look for types/effects only"
    end
  end

  def to_ast
    pass = FlattenProgramPass.new(@ctx, @env)
    ast = pass.process(@seed)
    return ast if @exprs.empty?

    effect_exprs = @exprs.map { |e| pass.process(e) }
    assigns = pass.var_expr.map { |id, e|
      s(RDL::Globals.types[:top], :lvasgn, "#{VAR_PREFIX}#{id}".to_sym, e)
    }

    s(ast.ttype, :begin, *[
      *assigns,
      *effect_exprs,
      ast # this is a hack, we can populate the return expression in a type driven way
    ])
  end

  def ==(other)
    to_ast == other.to_ast
  end

  def eql?(other)
    self == other
  end

  def hash
    to_ast.hash
  end

  def add_side_effect_expr(expr)
    @exprs << expr
  end

  def build_candidates
    update_types_pass = RefineTypesPass.new
    case @looking_for
    when :type
      pass1 = ExpandHolePass.new(@ctx, @env)
      expanded = pass1.process(@seed)
      expand_map = pass1.expand_map.map { |i| i.times.to_a }
      expand_map[0].product(*expand_map[1..expand_map.size]).map { |selection|
        pass2 = ExtractASTPass.new(selection, @env)
        program = update_types_pass.process(pass2.process(expanded))
        new_env = pass2.env
        prog_wrap = ProgWrapper.new(@ctx, program, new_env)
        prog_wrap.look_for(:type, @target)
        prog_wrap.passed_asserts = @passed_asserts
        prog_wrap
      }
    when :effect
      # TODO: ordering can be done better to build candidates programs with
      # method calls that can satisfy multiple effects at once
      RDL.type_cast(@target, 'Array<String>', force: true).map { |eff|
        methds = methods_with_write_effect(eff)
        eff_hole = s(RDL::Globals.types[:top], :hole, 1, {effect: true})
        pass1 = ExpandHolePass.new(@ctx, @env)
        pass1.effect_methds = methds
        expanded = pass1.process(eff_hole)
        expand_map = pass1.expand_map.map { |i| i.times.to_a }
        expand_map[0].product(*expand_map[1..expand_map.size]).map { |selection|
          raise RbSynError, "expected only one item" unless selection.size == 1
          read_eff = pass1.read_effs[selection.first]
          pass2 = ExtractASTPass.new(selection, @env)
          program = update_types_pass.process(pass2.process(expanded))
          new_env = pass2.env
          prog_wrap = ProgWrapper.new(@ctx, @seed, new_env, @exprs.dup)
          prog_wrap.add_side_effect_expr(program)
          prog_wrap.look_for(:teffect, read_eff)
          prog_wrap.passed_asserts = @passed_asserts
          prog_wrap
        }
      }.flatten
    when :teffect
      pass1 = ExpandHolePass.new(@ctx, @env)
      expanded = pass1.process(@exprs.last)
      expand_map = pass1.expand_map.map { |i| i.times.to_a }
      expand_map[0].product(*expand_map[1..expand_map.size]).map { |selection|
        pass2 = ExtractASTPass.new(selection, @env)
        program = pass2.process(expanded)
        new_env = pass2.env
        new_exprs = @exprs.dup
        new_exprs[-1] = program
        prog_wrap = ProgWrapper.new(@ctx, @seed, new_env, new_exprs)
        prog_wrap.look_for(:teffect, @target)
        prog_wrap.passed_asserts = @passed_asserts
        prog_wrap
      }
    else
      raise RbSynError, "can look for types/effects only"
    end
  end

  def methods_with_write_effect(eff)
    if eff == '*'
      effect_causing = []
      klasses = RDL::Globals.info.info.keys.map { |kls| RDL::Util.to_class(kls) }
      klasses.each { |klass|
        RDL::Globals.info.info.each { |cls, v1|
          v1.each { |meth, v2|
            v2.fetch(:write, ['']).each { |weff|
              next if weff.empty?
              cls_qual = RDL::Util.to_class(cls)
              cls_qual = RDL::Util.singleton_class_to_class(cls_qual) if cls_qual.singleton_class?
              if klass.ancestors.include? cls_qual
                kl = RDL::Util.to_class_str(klass)
                if RDL::Util.to_class(cls).singleton_class?
                  kls = RDL::Util.add_singleton_marker(kl)
                else
                  kls = klass
                end
                effect_causing << [kls, meth, v2.fetch(:read, [''])]
              else
                effect_causing << [cls, meth, v2.fetch(:read, [''])]
              end
            }
          }
        }
      }
      return effect_causing
    elsif eff.split('.').size <= 2
      effect_causing = []
      klass = RDL::Util.to_class(eff.split('.')[0])
      # klass = RDL::Util.singleton_class_to_class(klass) if klass.singleton_class?

      RDL::Globals.info.info.each { |cls, v1|
        v1.each { |meth, v2|
          v2.fetch(:write, ['']).each { |weff|
            cls_qual = RDL::Util.to_class(cls)
            cls_qual = RDL::Util.singleton_class_to_class(cls_qual) if cls_qual.singleton_class?
            if weff.include? 'self'
              if (klass.ancestors.include?(cls_qual) || (cls_qual == ActiveRecord_Relation && klass.ancestors.include?(ActiveRecord::Base)))
                weff = weff.gsub('self', klass.name)
              end
            end
            if EffectAnalysis.effect_leq(eff, weff)
              if klass.ancestors.include? cls_qual
                if RDL::Util.to_class(cls).singleton_class?
                  kls = RDL::Util.add_singleton_marker(eff.split('.')[0])
                else
                  kls = eff.split('.')[0]
                end
                effect_causing << [kls, meth, v2.fetch(:read, [''])]
              else
                effect_causing << [cls, meth, v2.fetch(:read, [''])]
              end
            end
          }
        }
      }
      return effect_causing
    else
      raise RbSynError, "don't know how to handle #{eff.inspect}"
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