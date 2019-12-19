class SpecProxy
  attr_reader :pre_blk, :post_blk, :inputs

  def initialize(mth_name)
    @mth_name = mth_name
  end

  def pre(&blk)
    @pre_blk = blk
  end

  def post(&blk)
    @post_blk = blk
  end

  def method_missing(m, *args, &blk)
    raise RuntimeError, "unknown function #{m}, have #{@mth_name}" unless @mth_name == m
    @inputs = args
  end
end

class SynthesizerProxy
  include AST
  require "minitest/assertions"
  include MiniTest::Assertions

  attr_accessor :assertions

  def initialize(mth_name, type, components)
    @ctx = Context.new
    @ctx.fn_call_depth = 5
    @ctx.components = [*Rbsyn::ActiveRecord::Utils.models, *components]
    @ctx.functype = RDL::Globals.parser.scan_str type
    raise RuntimeError, "expected method type" unless @ctx.functype.is_a? RDL::Type::MethodType

    @mth_name = mth_name.to_sym
    @specs = []
    @assertions = 0
  end

  def spec(desc, &blk)
    spc = SpecProxy.new @mth_name
    spc.instance_eval(&blk)
    @specs << spc
  end

  def reset(&blk)
    @ctx.reset_func = blk
  end

  def generate_program
    @specs.each { |spec|
      @ctx.add_example(spec.pre_blk, spec.inputs, spec.post_blk)
    }
    syn = Synthesizer.new(@ctx)
    max_args = @specs.map { |spec| spec.inputs.size }.max
    args = max_args.times.map { |t| "arg#{t}".to_sym }
    prog = syn.run
    # TODO: these types can be made more precise
    fn = s(@ctx.functype, :def, @mth_name,
      s(RDL::Globals.types[:top], :args, *args.map { |arg|
        s(RDL::Globals.types[:top], :arg, arg)
      }), prog)
    Unparser.unparse(fn)
  end
end

module SpecDSL
  def define(mth_name, type, components: [], &blk)
    syn_proxy = SynthesizerProxy.new(mth_name, type, components)
    syn_proxy.instance_eval(&blk)
  end
end
