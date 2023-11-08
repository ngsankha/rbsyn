module TypeOperations
  def compute_targs(trec, tmeth)
    # TODO: we use only the first definition, ignoring overloaded method definitions
    type = tmeth[0]
    targs = type.args
    return targs.map { |targ| RDL::Type::DynamicType.new } if ENV.key? 'DISABLE_TYPES'

    targs.map { |targ|
      case targ
      when RDL::Type::ComputedType
        bind = Class.new.class_eval { binding }
        bind.local_variable_set(:trec, trec)
        targ.compute(bind)
      else
        targ
      end
    }
  end

  def compute_tout(trec, tmeth, targs)
    # TODO: we use only the first definition, ignoring overloaded method definitions
    type = tmeth[0]
    return RDL::Type::DynamicType.new if ENV.key? 'DISABLE_TYPES'

    tret = type.ret
    case tret
    when RDL::Type::ComputedType
      bind = Class.new.class_eval { binding }
      bind.local_variable_set(:trec, trec)
      bind.local_variable_set(:targs, targs)
      tret.compute(bind)
    when RDL::Type::VarType
      if tret.name == :self
        trec
      else
        if trec.is_a? RDL::Type::AnnotatedArgType
          base = trec.type.base
          tparams = trec.type.params
        else
          base = trec.base
          tparams = trec.params
        end
        params = RDL::Wrap.get_type_params(base.to_s)[0]
        idx = params.index(tret.name)
        raise RbSynError, "unexpected" if idx.nil?
        tparams[idx]
      end
    else
      tret
    end
  end

  def parents_of(trecv)
    case trecv
    when RDL::Type::SingletonType
      cls = trecv.val
      if cls.is_a? Class
        cls.ancestors.map { |klass| RDL::Util.add_singleton_marker(klass.to_s) }
      else
        raise RbSynError, "expected only true/false" unless (cls == true || cls == false || cls.nil? || cls.is_a?(Symbol))
        cls.class.ancestors.map { |klass| klass.to_s }
      end
    when RDL::Type::PreciseStringType
      String.ancestors.map { |klass| klass.to_s }
    when RDL::Type::UnionType
      trecv.types.map { |type| parents_of type }.flatten
    when RDL::Type::GenericType
      if trecv.base.name == 'ActiveRecord_Relation'
        parents_of(trecv.base) + parents_of(trecv.params[0])
      else
        parents_of trecv.base
      end
    when RDL::Type::OptionalType
      parents_of trecv.type
    when RDL::Type::NominalType
      RDL::Util.to_class(trecv.name).ancestors.map { |klass| klass.to_s }
    when RDL::Type::FiniteHashType
      Hash.ancestors.map { |klass| klass.to_s }
    when RDL::Type::BotType
      []
    when RDL::Type::DynamicType
      RDL::Globals.info.info.keys
    when RDL::Type::AnnotatedArgType
      parents_of(trecv.type)
    else
      raise RbSynError, "unhandled type #{trecv.inspect}"
    end
  end

  def constructable?(targs, tenv, strict=false)
    bool = Proc.new { |targ| targ <= RDL::Globals.types[:bool] }
    targs.all? { |targ|
      case targ
      when RDL::Type::BotType, RDL::Type::TopType
        false
      when RDL::Type::FiniteHashType
        if strict
          targ.elts.values.all? { |v| constructable? [v], tenv, strict }
        else
          targ.elts.values.any? { |v| constructable? [v], tenv, strict }
        end
      when RDL::Type::OptionalType
        constructable? [targ.type], tenv, strict
      when RDL::Type::NominalType
        tenv.any? { |t| t <= targ }
      when RDL::Type::UnionType
        targ.types.any? { |t| constructable? [t], tenv, strict }
      when RDL::Type::SingletonType
        if [Symbol, TrueClass, FalseClass].include? targ.val.class
          true
        else
          raise RbSynError, "unhandled type #{targ.inspect}"
        end
      when bool
        true
      else
        raise RbSynError, "unhandled type #{targ.inspect}"
      end
    }
  end

  def types_from_tenv(tenv)
    tenv.values.to_set
  end

  def methods_of(trecv)
    Hash[*parents_of(trecv).map { |klass|
        RDL::Globals.info.info[klass]
      }.reject(&:nil?).collect { |h| h.to_a }.flatten]
  end
end