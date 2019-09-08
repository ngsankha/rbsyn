require 'unparser'

MAX_DEPTH = 5

class Synthesizer
  include AST

  def initialize
    @states = []
    @inputs = []
    @outputs = []
  end

  def add_example(input, output)
    # Marshal.load(Marshal.dump(o)) is an ugly way to clone objects
    @states << Marshal.load(Marshal.dump(Table.db))
    @inputs << input
    @outputs << output
  end

  def fn_args
    min_args = @inputs.map(&:length).min
    max_args = @inputs.map(&:length).max
    raise NotImplementedError if min_args != max_args
    Array.new(min_args) { |i| "arg#{i}".to_sym }
  end

  def fn_args_as_sexpr
    args = fn_args.map { |i| s(:arg, i) }
    s(:args, *args)
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
          # This is only required to call functions from the current
          # environment, fn_args is not the right thing to call here
          # possible_args = fn_args # our environment is just function args at the moment
          # possible_args.each { |arg| enum.yield s(:send, nil, arg) }

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
          vars = fn_args
          vars.each { |var|
            enum.yield s(:lvar, var)
          }
        else
          raise NotImplementedError
        end
      }
    end
  end

  def run
    generate(0).each { |prog|
      begin
        func = s(:def, :fn, fn_args_as_sexpr, prog)
        fn = eval(Unparser.unparse(func))
        outputs = @states.zip(@inputs).map { |state, input|
          Table.load(state)
          fn(*input) rescue next
        }
        return func if outputs == @outputs
      rescue Exception => e
        next
      end
    }
    raise "no candidates found"
  end
end
