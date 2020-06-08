class EffectAnalysis
  def self.effect_leq(e1, e2)
    # TODO: unhandled right now: Singleton classes
    raise RbSynError, "cannot have self during leq of effects" if has_self?([e1]) || has_self?([e2])

    if e1 == ''
      true
    elsif e1 == '*'
      if e2 == ''
        false
      elsif e2 == '*'
        true
      elsif e2.split('.').size == 1
        false
      elsif e2.split('.').size == 2
        false
      else
        raise RbSynError, "unexpected effect format"
      end
    elsif e1.split('.').size == 1
      if e2 == ''
        false
      elsif e2 == '*'
        true
      elsif e2.split('.').size == 1
        e1 == e2
      elsif e2.split('.').size == 2
        e1 == e2.split('.')[0]
      else
        raise RbSynError, "unexpected effect format"
      end
    elsif e1.split('.').size == 2
      if e2 == ''
        false
      elsif e2 == '*'
        true
      elsif e2.split('.').size == 1
        true
      elsif e2.split('.').size == 2
        e1 == e2
      else
        raise RbSynError, "unexpected effect format"
      end
    else
      raise RbSynError, "unexpected effect format"
    end
  end

  def self.effect_union(*es)
    raise RbSynError, "cannot have self during union of effects" if has_self? es
    union = es.map { |e| Set[*e] }
      .reduce { |e1, e2| e1 | e2 }
      .to_a

    if union.size > 1
      union.reject { |u| u == '' }
    else
      union
    end
  end

  def self.effect_of(ast, env, kind)
    return RDL.type_cast([], 'Array<String>') if ast.nil?

    case ast.type
    when :send
      klass_eff = effect_of(ast.children[0], env, kind)
      klass = type_of(ast.children[0], env)
      return [''] if klass == RDL::Globals.types[:bot]

      meth = ast.children[1]
      args = ast.children[2..].map { |arg| effect_of(arg, env, kind) }
      my_eff = case klass
      when RDL::Globals.types[:bool]
        []
      when RDL::Type::SingletonType
        RDL::Globals.info.get(RDL::Util.add_singleton_marker(klass.to_s), meth, kind)
      when RDL::Type::NominalType
        RDL::Globals.info.get(klass.name, meth, kind)
      when RDL::Type::FiniteHashType
        RDL::Globals.info.get('Hash', meth, kind)
      when RDL::Type::GenericType
        if klass.base.to_s == 'ActiveRecord_Relation'
          RDL::Globals.info.get(klass.params[0].to_s, meth, kind)
        else
          raise RbSynError, "unhandled type #{klass}"
        end
      else
        raise RbSynError, "unhandled type #{klass}"
      end

      my_eff ||= []
      my_eff.map! { |eff|
        case klass
        when RDL::Type::NominalType, RDL::Type::SingletonType
          eff.gsub('self', klass.to_s)
        else
          raise RbSynError, "unhandled type"
        end
      }
      effect_union(*([klass_eff, my_eff, args].flatten))
    when :ivar, :lvar, :str, :true, :false, :const, :sym, :nil, :int
      []
    when :begin
      effects = ast.children.map { |c| effect_of(c, env, kind) }
      effect_union(*effects.flatten)
    else
      raise RbSynError, "unhandled ast node #{ast.type}"
    end
  end

  def self.type_of(ast, env)
    case ast.type
    when :ivar, :lvar
      var_name = ast.children[0].to_sym
      return env[var_name] if env.key? var_name
      return RDL::Globals.types[:bot]
    when :int
      return RDL::Globals.types[:integer]
    when :const
      return RDL::Type::SingletonType.new(RDL::Util.to_class(ast.children[1].to_s))
    when :send
      klass = self.type_of(ast.children[0], env)
      meth = ast.children[1]
      tmeth = case klass
      when RDL::Type::SingletonType
        RDL::Globals.info.get(RDL::Util.add_singleton_marker(klass.to_s), meth, :type)
      when RDL::Type::NominalType
        RDL::Globals.info.get(klass.name, meth, :type)
      when RDL::Type::GenericType
        if RDL::Globals.info.get(klass.base.name, meth, :type)
          RDL::Globals.info.get(klass.base.name, meth, :type)
        else
          RDL::Globals.info.get(klass.params[0].name, meth, :type)
        end
      else
        raise RbSynError, "unhandled type #{klass}"
      end
      # take only the first type for now
      case tmeth[0]
      when RDL::Type::MethodType
        # we are not checking the types here
        # have faith in programmer
        # is that a good thing?
        return tmeth[0].ret
      when RDL::Type::ComputedType
        raise RbSynError, "TODO"
      else
        raise RbSynError, "unexpected #{tmeth.inspect}"
      end
    when :begin
      type_of(ast.children.last, env)
    else
      raise RbSynError, "unhandled ast node #{ast.type}"
    end
  end

  def self.replace_self(eff, target)
    eff.map { |e|
      if e == 'self'
        target
      else
        e.gsub('self.', "#{target}.")
      end
    }
  end

  private
  def self.has_self?(e)
    e.any? { |eff| (eff == 'self') || (eff.start_with? 'self.') }
  end
end