COVARIANT = :+
CONTRAVARIANT = :-
TRUE_POSTCOND = Proc.new { |result| result == true }

class Synthesizer
  include AST
  include SynHelper

  attr_reader :max_depth, :max_hash_size, :reset_fn, :components

  def initialize(tenv, max_depth: 5, max_hash_size: 1, components: [])
    @pre_conds = []
    @tenv = tenv
    @envs = []
    @post_conds = []
    @max_depth = max_depth
    @max_hash_size = max_hash_size
    @components = components
    @reset_fn = nil
  end

  def reset_function(blk)
    @reset_fn = blk
  end

  def add_test(input, pre, post)
    @pre_conds << pre
    @envs << env_from_args(input)
    @post_conds << post
  end

  def run(tout)
    progconds = @envs.zip(@post_conds, @pre_conds).map { |env, post, pre|
      progs = synthesize(@max_depth, tout, [env], @tenv, [post], [pre], @reset_fn)
      # branches = synthesize(@max_depth, RDL::Globals.types[:bool], [env], @tenv, [TRUE_POSTCOND], [pre], @reset_fn, [:true, :false])
      tuples = []
      progs.each { |prog|
        branches.each { |branch|
          tuples << ProgTuple.new(self, prog, branch, [env], [pre])
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
          possible = (mp + pp)
          possible.each { |t| t.prune_branches }
          results.push(*possible)
        }
      }

      # TODO: eliminate incorrect programs by testing?
      EliminationStrategy.descendants.each { |strategy|
        results = strategy.eliminate(results)
      }
      results
    }

    completed.each { |progcond|
      ast = progcond.to_ast
      test_outputs = @pre_conds.zip(@envs, @post_conds).map { |setup, env, post_cond|
        res = eval_ast(ast, env, @reset_fn) { setup.call unless setup.nil? } rescue next
        post_cond.call(res)
      }
      return ast if test_outputs.all?
    }
    raise RuntimeError, "No candidates found"
  end
end
