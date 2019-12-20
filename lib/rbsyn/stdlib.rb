RDL.nowrap :BasicObject

RDL.type :BasicObject, :!, '() -> %bool', effect: [:+, :+]

RDL.nowrap :Hash

RDL.type_params :Hash, [:k, :v], :all?
RDL.type :Hash, :[], '(``any_or_k(trec)``) -> ``output_type(trec, targs)``', effect: [:+, :+]

def any_or_k(trec)
  case trec
  when RDL::Type::FiniteHashType
    RDL::Type::UnionType.new(* trec.elts.keys.map { |sym| RDL::Type::SingletonType.new(sym) })
  else
    RDL::Globals.parser.scan_str "#T k"
  end
end

def output_type(trec, targs)
  case trec
  when RDL::Type::FiniteHashType
    targ = targs[0]
    case targ
    when RDL::Type::SingletonType
      trec.elts[targ.val]
    when RDL::Type::UnionType
      RDL::Type::UnionType.new(*targ.types.map { |t|
        val = trec.elts[t.val]
        val.is_a?(RDL::Type::OptionalType) ? val.type : val
      })
    else
      raise RuntimeError, "unhandled type"
    end
  else
    raise RuntimeError, "unhandled type"
  end
end
