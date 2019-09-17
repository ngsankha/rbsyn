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
    generate(0).each { |prog|
      begin
        outputs = @states.zip(@envs).map { |state, env|
          eval_ast(prog, state, env) rescue next
        }
        return prog if outputs == @outputs
      rescue Exception => e
        next
      end
    }
    raise "no candidates found"
  end

  private

  def env_from_args(input)
    env = ValEnvironment.new
    input.each_with_index { |v, i|
      env["arg#{i}".to_sym] = v
    }
    env
  end

  def generate(depth, fragments=nil)
    return [] unless depth <= MAX_DEPTH
    fragments ||= [:true, :false, :const, :send, :pair, :hash, :lvar]

    Enumerator.new do |enum|
      fragments.each { |f|
        case f
        when :true, :false
          enum.yield s(f)
        when :const
          consts = Set.new
          @states.each { |state| consts.merge(state.keys) }
          consts.each { |c|
            enum.yield s(:const, nil, c.to_s.to_sym)
          }
        when :send
          generate(depth + 1, [:const]).each { |recv|
            class_meths = Table.methods - Class.methods - [:db, :load, :reset, :fields]
            class_meths.each { |mth|
              generate(depth + 1, [:hash]).each { |arg|
                enum.yield s(:send, recv, mth, arg)
              }
            }
          }
        when :pair
          possible_fields = Table.db.keys.map { |k| k.fields }.flatten
          possible_fields.each { |field|
            lhs = s(:sym, field)
            generate(depth + 1, [:lvar]).each { |rhs|
              enum.yield s(:pair, lhs, rhs)
            }
          }
        when :hash
          generate(depth + 1, [:pair]).each { |child|
            enum.yield s(:hash, child)
          }
        when :lvar
          vars = Set.new(@envs.map(&:bindings).flatten)
          vars.each { |k, v|
            enum.yield s(:lvar, k)
          }
        else
          raise NotImplementedError
        end
      }
    end
  end
end
