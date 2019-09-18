MAX_DEPTH = 5

class Synthesizer
  include AST

  def initialize
    @states = []
    @envs = []
    @outputs = []
  end

  def add_example(input, output)
    Table.reset
    yield if block_given?
    # Marshal.load(Marshal.dump(o)) is an ugly way to clone objects
    @states << Marshal.load(Marshal.dump(Table.db))
    @envs << env_from_args(input)
    @outputs << output
    Table.reset
  end

  def run
    tenv = TypeEnvironment.new
    @envs.map(&:to_type_env).each { |t| tenv = tenv.merge(t) }
    tenv = load_components(tenv)

    toutenv = TypeEnvironment.new
    @outenv = @outputs.map { |o|
      env = ValEnvironment.new
      env[:out] = o
      env.to_type_env
    }.each { |t| toutenv = toutenv.merge(t) }

    tout = toutenv[:out].type
    initial_components = guess_initial_components(tout)

    generate(0, tout, tenv, initial_components).each { |prog|
      begin
        outputs = @states.zip(@envs).map { |state, env|
          eval_ast(prog, state, env) rescue next
        }
        return prog if outputs == @outputs
      rescue Exception => e
        next
      end
    }
    raise RuntimeError, "No candidates found"
  end

  private

  def env_from_args(input)
    env = ValEnvironment.new
    input.each_with_index { |v, i|
      env["arg#{i}".to_sym] = v
    }
    env
  end

  def load_components(env)
    raise RuntimeError unless env.is_a? TypeEnvironment
    # TODO: think of better ways to load components than hard coded list
    env[:User] = RDL::Type::SingletonType.new(User)
    env[:UserEmail] = RDL::Type::SingletonType.new(UserEmail)
    env
  end

  def cls_mths_with_type_defns(cls)
    cls = RDL::Util.to_class(cls.to_s)
    parents = cls.ancestors
    parents = parents[0...parents.index(Object)]
    Hash[*parents.map { |parent|
      klass = RDL::Util.add_singleton_marker(parent.to_s)
      RDL::Globals.info.info[klass]
    }.reject(&:nil?).collect { |h| h.to_a }.flatten]
  end

  def compute_targs(trec, tmeth)
    # TODO: we use only the first definition, ignoring overloaded method definitions
    type = tmeth[0]
    targs = type.args
    targs.map { |targ|
      bind = Class.new.class_eval { binding }
      bind.local_variable_set(:trec, trec)
      targ.compute(bind)
    }
  end

  def guess_initial_components(tout)
    always = [:send, :lvar]

    if tout <= RDL::Globals.types[:bool]
      [:true, :false, *always]
    else
      always
    end
  end

  def generate(depth, type, tenv, components, extra={})
    return [] unless depth <= MAX_DEPTH

    Enumerator.new do |enum|
      components.each { |f|
        case f
        when :true, :false
          ty = RDL::Globals.types[:bool]
          raise RuntimeError unless type <= ty
          enum.yield s(f)
        when :const
          ty = RDL::Type::NominalType.new(Class)
          raise RuntimeError unless type <= ty
          consts = tenv.bindings_with_type(ty).select { |k, v| v.type <= type }
          consts.each { |k, v|
            enum.yield s(:const, nil, k)
          }
        when :send
          # TODO: support method calls on static objects only for now
          generate(depth + 1, RDL::Type::NominalType.new(Class), tenv, [:const]).each { |recv|
            # List only methods with type definitions
            # TODO: Handle all objects and not just static methods on classes
            recv_cls = recv.children[1]
            class_meths = cls_mths_with_type_defns(recv_cls)
            class_meths.each { |mth, info|
              targs = compute_targs(tenv[recv_cls].type, info[:type])
              # TODO: we only handle the first argument now
              targ = targs[0]
              case targ
              when RDL::Type::FiniteHashType
                generate(depth + 1, targ, tenv, [:hash]).each { |arg|
                  enum.yield s(:send, recv, mth, arg)
                }
              else
                raise RuntimeError, "Don't know how to handle #{targs}"
              end
            }
          }
        when :hash
          raise RuntimeError unless type.is_a? RDL::Type::FiniteHashType
          # TODO: generate hashes with multiple keys
          # TODO: some hashes can have mandatory keys too
          type.elts.each { |k, t|
            raise RuntimeError unless t.is_a? RDL::Type::OptionalType
            t = t.type
            generate(depth + 1, t, tenv, [:pair], { key: k }).each { |pair|
              enum.yield s(:hash, pair)
            }
          }
        when :pair
          raise RuntimeError unless extra.key? :key
          lhs = s(:sym, extra[:key])
          choices = tenv.bindings_with_type(type)
          choices.each { |var, binding|
            generate(depth + 1, type, tenv, [:lvar], { value: var }).each { |rhs|
              enum.yield s(:pair, lhs, rhs)
            }
          }
        when :lvar
          if extra.key? :value
            enum.yield s(:lvar, extra[:value])
          else
            # functions return values will be subtype of the return type in function sig
            choices = tenv.bindings_with_supertype(type)
            choices.each { |var, binding|
              enum.yield s(:lvar, var)
            }
          end
        else
          raise NotImplementedError
        end
      }
    end
  end
end
