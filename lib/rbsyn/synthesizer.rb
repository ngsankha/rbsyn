COVARIANT = :+
CONTRAVARIANT = :-
TRUE_POSTCOND = Proc.new { |result| result == true }

class Synthesizer
  include AST
  include SynHelper

  def initialize(ctx)
    @ctx = ctx
  end

  def run
    raise RuntimeError, "No candidates found"
  end
end
