class UpdateTypesPass < ::AST::Processor
  include TypeOperations

  def on_send(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })

    trecv = node.children[0].ttype
    mth = node.children[1]
    mthds = methods_of(trecv)
    info = mthds[mth]
    tmeth = info[:type]
    targs = node.children[2..].map &:ttype
    # puts "#{trecv}, #{mth} (#{targs.join(', ')}) -> #{node.ttype}"
    begin
      tret = compute_tout(trecv, tmeth, targs)
      node.update_ttype(tret)
    rescue
    end
  end

  def handler_missing(node)
    node.updated(nil, node.children.map { |k|
      k.is_a?(TypedNode) ? process(k) : k
    })
  end
end
