class Context
  attr_accessor :fn_call_depth, :components, :preconds, :args, :postconds,
    :reset_func, :functype

  def initialize
    @fn_call_depth = 0
    @components = []
    @precond = []
    @args = []
    @postcond = []
    @reset_func = nil
    @functype = nil
  end

  def add_example(precond, arg, postcond)
    @preconds << precond
    @args << arg
    @postconds << postcond
  end
end
