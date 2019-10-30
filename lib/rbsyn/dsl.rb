class SpecProxy
  attr_reader :pre_blk, :post_blk, :inputs

  def initialize(mth_name)
    @mth_name
  end

  def pre(&blk)
    @pre_blk = blk
  end

  def post(&blk)
    @post_blk = blk
  end

  def method_missing(m, *args, &blk)
    raise RuntimeError, "unknown function" unless @mth_name == m
    @inputs = args
  end
end

class SynthesizerProxy
  include AST

  def initialize(mth_name)
    @mth_name = mth_name.to_sym
    @specs = []
  end

  def spec(desc, &blk)
    spc = SpecProxy.new
    spc.instance_eval(&blk)
    @specs << spc
  end

  def reset(&blk)
    @reset_fn = blk
  end

  def generate_program
    syn = Synthesizer.new(components: Rbsyn::ActiveRecord::Utils.models)
    @specs.each { |spec|
      syn.add_test(spec.inputs, spec.pre_blk, spec.post_blk)
    }
    max_args = @specs.map { |spec| spec.inputs.size }.max
    args = max_args.times.map { |t| "arg#{t}".to_sym }
    prog = syn.run
    fn = s(:def, @mth_name,
      s(:args, *args.map { |arg| s(:arg, arg) }),
      prog)
    Unparser.unparse(fn)
  end
end

module SpecDSL
  def self.define(mth_name, &blk)
    syn = SynthesizerProxy.new(mth_name)
    syn_proxy.instance_exec(syn) { blk.call }
  end
end
