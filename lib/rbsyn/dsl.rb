class SpecProxy
  attr_reader :pre_blk, :post_blk

  def initialize(mth_name)
    @mth_name = mth_name
  end

  def setup(&blk)
    @pre_blk = blk
  end

  def post(&blk)
    @post_blk = blk
  end
end

class SynthesizerProxy
  include AST
  require "minitest/assertions"
  include Minitest::Assertions

  attr_accessor :assertions

  def initialize(mth_name, type, components, prog_size, max_hash_size, consts, enable_nil)
    @ctx = Context.new
    @ctx.max_prog_size = prog_size
    @ctx.components = components
    @ctx.functype = RDL::Globals.parser.scan_str type
    @ctx.max_hash_size = max_hash_size
    @ctx.enable_constants = consts
    @ctx.enable_nil = enable_nil
    raise RbSynError, "expected method type" unless @ctx.functype.is_a? RDL::Type::MethodType

    @mth_name = mth_name.to_sym
    @ctx.mth_name = @mth_name
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
    if ENV.key? 'TIMEOUT'
      timeout = ENV['TIMEOUT'].strip.to_i
    else
      timeout = 300
    end
    Timeout::timeout(timeout) {
      @specs.each { |spec|
        @ctx.add_example(spec.pre_blk, spec.post_blk)
      }
      syn = Synthesizer.new(@ctx)
      max_args = @ctx.functype.args.size
      args = max_args.times.map { |t| "arg#{t}".to_sym }
      prog = syn.run
      # TODO: these types can be made more precise
      fn = s(@ctx.functype, :def, @mth_name,
        s(RDL::Globals.types[:top], :args, *args.map { |arg|
          s(RDL::Globals.types[:top], :arg, arg)
        }), prog.to_ast)
      src = Unparser.unparse(fn)
      Instrumentation.prog = src
      Instrumentation.specs = @specs.size
      src
    }
  end
end

module SpecDSL
  def define(mth_name, type, components, prog_size: 5, max_hash_size: 1, consts: false, enable_nil: false, &blk)
    syn_proxy = SynthesizerProxy.new(mth_name, type, components, prog_size, max_hash_size, consts, enable_nil)
    syn_proxy.instance_eval(&blk)
  end
end
