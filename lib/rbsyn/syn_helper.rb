module SynHelper
  include TypeOperations

  def syn_bool(component, tenv, tout, variance, extra={})
    type = RDL::Globals.types[:bool]
    raise RuntimeError, "type mismatch for boolean" unless tout <= type
    return [TypedAST.new(RDL::Globals.types[component], s(component))], []
  end

  def syn_const(component, tenv, tout, variance, extra={})
    type = RDL::Type::NominalType.new(Class)
    raise RuntimeError, "type mismatch for const" unless tout <= type
    consts = tenv.bindings_with_type(type).select { |k, v| v.type <= tout }
    return consts.map { |k, v|
      TypedAST.new(RDL::Type::SingletonType.new(RDL::Util.to_class(k)), s(:const, nil, k))
    }, []
  end

  def syn_send(component, tenv, tout, variance, extra={})
    raise RuntimeError, "function calls can only be contravariant" if variance == COVARIANT
    guesses = []

    reach_set = extra[:reach_set]
    raise RuntimeError, "reach set is nil" if reach_set.nil?

    reach_set.each { |path|
      tokens = path.path.to_enum
      exprs = []
      loop {
        begin
          trecv = tokens.next
          mth = tokens.next
          if exprs.empty?
            break if trecv.is_a? RDL::Type::PreciseStringType
            raise RuntimeError, "expected first element to be singleton" unless trecv.is_a? RDL::Type::SingletonType
            consts = syn(:const, tenv, trecv, COVARIANT)
            raise RuntimeError, "unexpected holes" unless consts[1].size == 0
            consts[0].each { |const|
              mthds = methods_of(trecv)
              info = mthds[mth]
              tmeth = info[:type]
              targs = compute_targs(trecv, tmeth)
              # TODO: we only handle the first argument now
              targ = targs[0]
              case targ
              when RDL::Type::FiniteHashType
                tret = compute_tout(trecv, tmeth, targs)
                hashes = syn(:hash, tenv, targ, COVARIANT)
                raise RuntimeError, "unexpected holes" unless hashes[1].size == 0
                exprs.concat hashes[0].map { |h|
                  # TODO: more type checking here for chains longer than 1
                  TypedAST.new(tret, s(:send, const.expr, mth, h.expr))
                }
              when RDL::Type::SingletonType
                raise RuntimeError, "cannot handle anything other than symbol" unless targ.val.is_a? Symbol
                tret = compute_tout(trecv, tmeth, targs)
                exprs << TypedAST.new(tret, s(:send, const.expr, mth, s(:sym, targ.val)))
              when RDL::Type::NominalType
                tret = compute_tout(trecv, tmeth, targs)
                args = syn(:lvar, tenv, targ, COVARIANT)
                raise RuntimeError, "unexpected holes" unless args[1].size == 0
                exprs.concat args[0].map { |arg| TypedAST.new(tret, s(:send, const.expr, mth, arg.expr)) }
              else
                raise RuntimeError, "Don't know how to handle #{targ.inspect}"
              end
            }
          else
            mthds = methods_of(trecv)
            info = mthds[mth]
            tmeth = info[:type]
            targs = compute_targs(trecv, tmeth)
            targ = targs[0]
            new_exprs = []
            case targ
            when nil
              exprs.each { |expr|
                tret = compute_tout(trecv, tmeth, nil)
                new_exprs << TypedAST.new(tret, s(:send, expr.expr, mth))
              }
            when RDL::Type::FiniteHashType
              hashes = syn(:hash, tenv, targ, COVARIANT)
              raise RuntimeError, "unexpected holes" unless hashes[1].size == 0
              hashes[0].each { |h|
                exprs.each { |expr|
                  tret = compute_tout(trecv, tmeth, targs)
                  new_exprs << TypedAST.new(tret, s(:send, expr.expr, mth, h.expr))
                }
              }
            else
              raise RuntimeError, "Don't know how to handle #{targ.inspect}"
            end
            exprs = new_exprs
          end
        rescue StopIteration => err
          break
        end
      }
      guesses.concat(exprs)
    }

    return guesses, []
  end

  def syn_hash(component, tenv, tout, variance, extra={})
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

  def syn_lvar(component, tenv, tout, variance, extra={})
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

  def syn(component, tenv, tout, variance, extra={})
    # TODO: better way to handle errors when max depth is reached?
    case component
    when :true, :false
      syn_bool component, tenv, tout, variance
    when :const, :send, :hash, :lvar
      handler = "syn_#{component}".to_sym
      send handler, component, tenv, tout, variance, extra
    else
      raise RuntimeError, "unknown ast node"
    end
  end

  def synthesize(max_depth, envs, outputs, setups, forbidden_components=[])
    tenv = TypeEnvironment.new
    envs.map(&:to_type_env).each { |t| tenv = tenv.merge(t) }
    tenv = load_components(tenv)

    toutenv = TypeEnvironment.new
    outputs.map { |o|
      env = ValEnvironment.new
      env[:out] = o
      env.to_type_env
    }.each { |t| toutenv = toutenv.merge(t) }
    tout = toutenv[:out].type
    initial_components = guess_initial_components(tout) - forbidden_components

    (max_depth + 1).times { |depth|
      progs = generate(depth, tenv, initial_components, tout).select { |prog|
        prog = prog.expr
        begin
          run_outputs = setups.zip(envs).map { |setup, env|
            eval_ast(prog, env) { setup.call unless setup.nil? } rescue next
          }
          run_outputs == outputs
        rescue Exception => e
          next
        end
      }
      return progs if progs.size > 0
    }
    raise RuntimeError, "No candidates found"
  end

  def env_from_args(input)
    env = ValEnvironment.new
    input.each_with_index { |v, i|
      env["arg#{i}".to_sym] = v
    }
    env
  end

  def load_components(env)
    raise RuntimeError unless env.is_a? TypeEnvironment
    @components.each { |c|
      env[c.to_s.to_sym] = RDL::Type::SingletonType.new(c)
    }
    env
  end

  def guess_initial_components(tout)
    always = [:send, :lvar]

    return [:true, :false, *always] if tout <= RDL::Globals.types[:bool]
    return always
  end

  def generate(depth, tenv, components, tout)
    if depth == 0
      components = components - [:send]
      components.map { |component|
        # syn returns 2 values. The first one is the set of concrete programs,
        # and the second one is the set of programs with holes.
        # The second one is always empty at the moment as we don't actually make
        # use of holes at the moment
        syn(component, tenv, tout, CONTRAVARIANT)[0]
      }.flatten
    else
      r = Reachability.new(tenv)
      paths = r.paths_to_type(tout, depth)

      components.map { |component|
        # syn returns 2 values. The first one is the set of concrete programs,
        # and the second one is the set of programs with holes.
        # The second one is always empty at the moment as we don't actually make
        # use of holes at the moment
        syn(component, tenv, tout, CONTRAVARIANT, { reach_set: paths })[0]
      }.flatten
    end
  end
end
