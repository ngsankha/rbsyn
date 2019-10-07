module SynHelper
  def syn_bool(component, tenv, tout, variance)
    type = RDL::Globals.types[:bool]
    raise RuntimeError, "type mismatch for boolean" unless tout <= type
    return [TypedAST.new(RDL::Globals.types[component], s(component))], []
  end

  def syn_const(component, tenv, tout, variance)
    type = RDL::Type::NominalType.new(Class)
    raise RuntimeError, "type mismatch for const" unless tout <= type
    consts = tenv.bindings_with_type(type).select { |k, v| v.type <= tout }
    return consts.map { |k, v|
      TypedAST.new(RDL::Type::SingletonType.new(RDL::Util.to_class(k)), s(:const, nil, k))
    }, []
  end

  def syn_send(component, tenv, tout, variance)
    raise RuntimeError, "function calls can only be contravariant" if variance == COVARIANT
    guesses = []

    consts = syn(:const, tenv, RDL::Type::NominalType.new(Class), COVARIANT)
    raise RuntimeError, "unexpected holes" unless consts[1].size == 0
    consts[0].map { |recv|
      recv_type = recv.type
      recv_cls = recv.expr.children[1]
      class_meths = cls_mths_with_type_defns(recv_cls)
      class_meths.each { |mth, info|
        targs = compute_targs(recv_type, info[:type])
        # TODO: we only handle the first argument now
        targ = targs[0]
        case targ
        when RDL::Type::FiniteHashType
          hashes = syn(:hash, tenv, targ, COVARIANT)
          raise RuntimeError, "unexpected holes" unless hashes[1].size == 0
          guesses.concat hashes[0].map { |h|
            tret = compute_tout(recv_type, info[:type], targs)
            next unless tret <= tout
            TypedAST.new(tret, s(:send, recv.expr, mth, h.expr))
          }.reject { |e| e.nil? }
        when RDL::Type::SingletonType
          case targ.val
          when Symbol
            tret = compute_tout(recv_type, info[:type], targs)
            guesses << TypedAST.new(tret, s(:send, recv.expr, mth, s(:sym, targ.val))) if tret <= tout
          else
            raise RuntimeError, "Don't know how to emit singletons apart from symbol"
          end
        else
          raise RuntimeError, "Don't know how to handle #{targ}"
        end
      }
    }

    # Compute hole expr
    hole_expr = s(:hole, HoleInfo.new(tout))
    return guesses, [hole_expr]
  end

  def syn_hash(component, tenv, tout, variance)
    raise RuntimeError unless tout.is_a? RDL::Type::FiniteHashType

    guesses = []
    # TODO: generate hashes with multiple keys
    # TODO: some hashes can have mandatory keys too
    tout.elts.each { |k, t|
      raise RuntimeError, "expect everything to be optional in a hash" unless t.is_a? RDL::Type::OptionalType
      t = t.type
      lvars = syn(:lvar, tenv, t, COVARIANT)
      raise RuntimeError, "unexpected holes" unless lvars[1].size == 0
      guesses.concat lvars[0].map { |v|
        TypedAST.new(RDL::Type::FiniteHashType.new({k: v.type}, nil), s(:hash, s(:pair, s(:sym, k), v.expr)))
      }
    }

    return guesses, []
  end

  def syn_lvar(component, tenv, tout, variance)
    vars = case variance
    when CONTRAVARIANT
      tenv.bindings_with_supertype(tout)
    when COVARIANT
      tenv.bindings_with_type(tout)
    end

    return vars.map { |var, bind|
      TypedAST.new(RDL::Type::NominalType.new(bind.type), s(:lvar, var))
    }, []
  end

  def syn(component, tenv, tout, variance)
    # TODO: better way to handle errors when max depth is reached?
    case component
    when :true, :false
      syn_bool component, tenv, tout, variance
    when :const, :send, :hash, :lvar
      handler = "syn_#{component}".to_sym
      send handler, component, tenv, tout, variance
    else
      raise RuntimeError, "unknown ast node"
    end
  end
end
