module TypeOperations
  def compute_targs(trec, tmeth)
    # TODO: we use only the first definition, ignoring overloaded method definitions
    type = tmeth[0]
    targs = type.args
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
    tret = type.ret
    case tret
    when RDL::Type::ComputedType
      bind = Class.new.class_eval { binding }
      bind.local_variable_set(:trec, trec)
      bind.local_variable_set(:targs, targs)
      tret.compute(bind)
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
        raise RuntimeError, "expected only true/false" unless (cls == true || cls == false)
        cls.class.ancestors.map { |klass| klass.to_s }
      end
    when RDL::Type::PreciseStringType
      String.ancestors.map { |klass| klass.to_s }
    when RDL::Type::UnionType
      trecv.types.map { |type| parents_of type }.flatten
    when RDL::Type::GenericType
      parents_of trecv.base
    when RDL::Type::NominalType
      RDL::Util.to_class(trecv.name).ancestors.map { |klass| klass.to_s }
    else
      raise RuntimeError, "unhandled type #{trecv.inspect}"
    end
  end

  def constructable?(targs, tenv, strict=false)
    targs.all? { |targ|
      case targ
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
      when RDL::Type::SingletonType
        if targ.val.is_a? Symbol
          true
        else
          raise RuntimeError, "unhandled type #{targ.inspect}"
        end
      else
        raise RuntimeError, "unhandled type #{targ.inspect}"
      end
    }
  end

  def types_from_tenv(tenv)
    s = Set.new
    tenv.bindings.each { |b|
      s.add(tenv[b].type)
    }
    return s
  end

  def methods_of(trecv)
    Hash[*parents_of(trecv).map { |klass|
        RDL::Globals.info.info[klass]
      }.reject(&:nil?).collect { |h| h.to_a }.flatten]
  end
end