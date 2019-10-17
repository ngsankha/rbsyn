COVARIANT = :+
CONTRAVARIANT = :-

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
    progconds = @envs.zip(@outputs, @test_setup).map { |env, output, setup|
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

    # if there is only one generated, there is nothing to merge, we return the first synthesized program
    return progconds[0][0].prog.expr if progconds.size == 1

    completed = progconds.reduce { |merged_prog, progcond|
      results = []
      merged_prog.each { |mp|
        progcond.each { |pp|
          t = (mp + pp)
          t.prune_branches
          results << t
        }
      }
      # TODO: eliminate incorrect programs by testing?
      results = BranchCountElimination.eliminate(results)
      OrCountElimination.eliminate(results)
    }

    completed.each { |progcond|
      ast = progcond.to_ast
      test_outputs = @test_setup.zip(@envs).map { |setup, env|
        eval_ast(ast, env) { setup.call unless setup.nil? } rescue next
      }
      return ast if test_outputs == @outputs
    }
    raise RuntimeError, "No candidates found"
  end
end
