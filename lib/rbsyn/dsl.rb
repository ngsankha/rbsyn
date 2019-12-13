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
    @mth_name = mth_name.to_sym
    @components = [*Rbsyn::ActiveRecord::Utils.models, *components]
    @specs = []
    @type = RDL::Globals.parser.scan_str type
    @assertions = 0
    raise RuntimeError, "expected method type" unless @type.is_a? RDL::Type::MethodType
  end

  def spec(desc, &blk)
    spc = SpecProxy.new @mth_name
    spc.instance_eval(&blk)
    @specs << spc
  end

  def reset(&blk)
    @reset_fn = blk
  end

  def generate_program
    syn = Synthesizer.new(components: @components)
    syn.reset_function @reset_fn unless @reset_fn.nil?
    @specs.each { |spec|
      syn.add_test(spec.inputs, spec.pre_blk, spec.post_blk)
    }
    max_args = @specs.map { |spec| spec.inputs.size }.max
    args = max_args.times.map { |t| "arg#{t}".to_sym }
    prog = syn.run @type.ret
    fn = s(:def, @mth_name,
      s(:args, *args.map { |arg| s(:arg, arg) }),
      prog)
    Unparser.unparse(fn)
  end
end

module SpecDSL
  def define(mth_name, type, components: [], &blk)
    syn_proxy = SynthesizerProxy.new(mth_name, type, components)
    syn_proxy.instance_eval(&blk)
  end
end
