module Assertions
  # Note: The same count will correspond to the same failure reason all the time
  def assert(&blk)
    @count += 1
    ans = yield
    if !!ans
      @passed_count += 1
      ans
    else
      return if ENV.key? 'DISABLE_EFFECTS'
      ret = @ctx.functype.ret
      raise RuntimeError, "expected only one parameter" unless @params.size == 1
      type_env = {}
      # @params is a parameters of post block
      type_env[@params[0].to_sym] = ret
      @ctx.curr_binding.eval("instance_variables").each { |v|
        # TODO: Only generates nominal types for now
        type_env[v.to_sym] = RDL::Type::NominalType.new(@ctx.curr_binding.eval("#{v}.class.name"))
      }

      # Ugly hack! See https://github.com/whitequark/parser/issues/343
      header = "#{@params[0]} = nil\n"
      ast = Parser::CurrentRuby.parse(header + blk.source)
      # AST looks something like
      # (begin
      #   (lvasgn :user
      #     (nil))
      #   (block
      #     (send nil :assert)
      #     (args)
      #     (send
      #       (send
      #         (lvar :user) :id) :==
      #       (send
      #         (ivar :@staged) :id))))

      read_set = EffectAnalysis.effect_of(ast.children.last.children.last, type_env, :read)
      write_set = EffectAnalysis.effect_of(ast.children.last.children.last, type_env, :write)
      raise AssertionError.new(@passed_count, read_set, write_set)
    end
  end
end
