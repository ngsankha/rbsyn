COVARIANT = :+
CONTRAVARIANT = :-

class TypedAST
  attr_reader :type, :expr

  def initialize(type, expr)
    @type = type
    @expr = expr
  end

  def to_s
    "#{Unparser.unparse(@expr)} : #{@type}"
  end
end

class Synthesizer
  include AST
  include SynHelper

  def initialize(max_depth: 5, components: [])
    @test_setup = []
    @envs = []
    @outputs = []
    @max_depth = max_depth
    @components = components
  end

  def add_example(input, output, &blk)
    DBUtils.reset
    yield if block_given?
    @test_setup << blk
    @envs << env_from_args(input)
    @outputs << output
    DBUtils.reset
  end

  def run
    prog_pcs = @envs.zip(@outputs, @test_setup).map { |env, output, setup|
      progs = synthesize(@max_depth, [env], [output], [setup])
      branches = synthesize(@max_depth, [env], [true], [setup], [:true, :false])
      tuples = []
      progs.each { |prog|
        branches.each { |branch|
          tuples << ProgTuple.new(prog, branch, [env], [setup])
        }
      }
      tuples
    }

    # if there is only one test there is nothing to merge, we return the first synthesized program
    return prog_pcs[0][0].prog if prog_pcs.size == 1

    prog_pcs.reduce { |merged_prog, prog_pc|
      merged_prog.each { |mp|
        prog_pc.each { |pp|
          merged = mp + pc
        }
      }
    }
  end
end
