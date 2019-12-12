module SynHelper
  include TypeOperations

  def syn_bool(component, tenv, tout, variance, extra={})
    type = RDL::Globals.types[:bool]
    raise RuntimeError, "type mismatch for boolean" unless tout <= type
    return [TypedAST.new(RDL::Globals.types[:bool], s(component))]
  end

  def syn_const(component, tenv, tout, variance, extra={})
    type = RDL::Type::NominalType.new(Class)
    raise RuntimeError, "type mismatch for const" unless tout <= type
    consts = tenv.bindings_with_type(type).select { |k, v| v.type <= tout }
    return consts.map { |k, v|
      if v.type.is_a?(RDL::Type::SingletonType) && v.type.val.nil?
        TypedAST.new(v.type, s(:const, nil, k))
      else
        TypedAST.new(RDL::Type::SingletonType.new(RDL::Util.to_class(k)), s(:const, nil, k))
      end
    }
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
            if trecv.is_a? RDL::Type::SingletonType
              consts = syn(:const, tenv, trecv, COVARIANT)
            else
              # TODO: support calls on lvars
              consts = syn(:lvar, tenv, trecv, COVARIANT)
            end
            consts.each { |const|
              mthds = methods_of(trecv)
              info = mthds[mth]
              tmeth = info[:type]
              targs = compute_targs(trecv, tmeth)
              # TODO: we only handle the first argument now
              targ = targs[0]
              case targ
              when nil
                tret = compute_tout(trecv, tmeth, nil)
                exprs << TypedAST.new(tret, s(:send, const.expr, mth))
              when RDL::Type::FiniteHashType
                tret = compute_tout(trecv, tmeth, targs)
                hashes = syn(:hash, tenv, targ, COVARIANT)
                exprs.concat hashes.map { |h|
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
                exprs.concat args.map { |arg| TypedAST.new(tret, s(:send, const.expr, mth, arg.expr)) }
              when RDL::Type::UnionType
                raise RuntimeError, "only singletons supported at the moment" unless targ.types.all? { |t| t.is_a? RDL::Type::SingletonType }
                require "pry"; binding.pry
                exprs.concat targ.types.map { |t|
                  tret = compute_tout(trecv, tmeth, [t])
                  TypedAST.new(tret, s(:sym, t.val))
                }
              else
                raise RuntimeError, "Don't know how to handle #{targ}"
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
              hashes.each { |h|
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
      puts guesses
    }

    return guesses
  end

  def hash_combinations(thash, size)
    choices = thash.elts.to_a.combination(size).map { |arr| RDL::Type::FiniteHashType.new(Hash[arr], nil) }
    choices.map { |choice|
      choice = choice.elts
      rest = choice.reject { |k, v| v.is_a? RDL::Type::FiniteHashType }
      hashes = choice.select { |k, v| v.is_a? RDL::Type::FiniteHashType }
      hashes_arr = []
      hashes.each { |k, v|
        hash_choices = []
        hash_size = v.elts.size
        hash_size.times { |hs|
          hs += 1
          hash_choices.push(*hash_combinations(v, hs))
        }
        hash_choices.map! { |h| [k, h] }
        hashes_arr << hash_choices
      }

      if hashes_arr.empty?
        [RDL::Type::FiniteHashType.new(rest, nil)]
      else
        [rest.to_a].product(*hashes_arr).map { |h|
          first = h.shift
          h = [*h, *first]
          RDL::Type::FiniteHashType.new(Hash[h], nil)
        }
      end
    }.flatten(1)
  end

  def thash_to_sexpr(thash, tenv)
    keyvals = []
    choices = thash.elts.map { |k, v|
      if v.is_a? RDL::Type::FiniteHashType
        subhashes = syn(:hash, tenv, v, COVARIANT)
        subhashes.map { |subhash| s(:pair, s(:sym, k), subhash.expr) }
      else
        raise RuntimeError, "expected optional type" unless v.is_a? RDL::Type::OptionalType
        v = v.type
        lvars = syn(:lvar, tenv, v, COVARIANT)
        lvars.append(syn(:send, tenv, v, CONTRAVARIANT, { reach_set: one_call_away(tenv, v) }))
        if v <= RDL::Globals.types[:bool]
          lvars.push(*syn(:true, tenv, v, COVARIANT))
          lvars.push(*syn(:false, tenv, v, COVARIANT))
        end
        lvars.map { |lvar| s(:pair, s(:sym, k), lvar.expr) }
      end
    }
    if choices.size == 1
      choices[0].map { |choice| s(:hash, choice) }
    else
      choices[0].product(*choices[1..choices.size]).map { |choice| s(:hash, *choice) }
    end
  end

  # TODO: remove this, and move to a hole based approach
  def one_call_away(tenv, tout)
    r = Reachability.new(tenv)
    r.paths_to_type(tout, 1)
  end

  def syn_hash(component, tenv, tout, variance, extra={})
    raise RuntimeError unless tout.is_a? RDL::Type::FiniteHashType

    guesses = []

    # TODO: some hashes can have mandatory keys too
    tout.elts.each { |k, t| raise RuntimeError, "expect everything to be optional in a hash" unless t.is_a? RDL::Type::OptionalType }
    possible_types = []
    @max_hash_size.times { |ts|
      ts += 1
      possible_types.push(*hash_combinations(tout, ts))
    }

    possible_types.select! { |t| constructable?([t], types_from_tenv(tenv), true) }

    possible_types.each { |t|
      guesses.concat thash_to_sexpr(t, tenv).map { |concrete|
        TypedAST.new(t, concrete)
      }
    }

    return guesses
  end

  def syn_hole(component, tenv, tout, variance, extra={})
    TypedAST.new(tout, s(:hole, HoleInfo.new(tout)))
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
    }
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

  def synthesize(max_depth, tout, envs, tenv, outputs, setups, reset_fn, forbidden_components=[])
    tenv = load_components(tenv)

    toutenv = TypeEnvironment.new
    # TODO: Type can be automatically inferred by running the post block with result as a dummy object.
    # Methods calls like == or eql? will get the value, and from that we can infer the type
    initial_components = guess_initial_components(tout) - forbidden_components

    (max_depth + 1).times { |depth|
      progs = generate(depth, tenv, initial_components, tout).select { |prog|
        prog = prog.expr
        tested = setups.zip(envs, outputs).map { |setup, env, output|
          res = eval_ast(prog, env, reset_fn) { setup.call unless setup.nil? } rescue next
          output.call(res)
        }
        tested.all?
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
        syn(component, tenv, tout, CONTRAVARIANT)
      }.flatten
    else
      r = Reachability.new(tenv)
      paths = r.paths_to_type(tout, depth)

      tmp = components.map { |component|
        syn(component, tenv, tout, CONTRAVARIANT, { reach_set: paths })
      }.flatten
      puts tmp
      return tmp
    end
  end
end