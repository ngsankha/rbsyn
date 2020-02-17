RDL.type RDL::Globals, 'self.types', '() -> Hash<Symbol, RDL::Type::Type>'
RDL.type MiniSat::Var, :-@, '() -> MiniSat::Var'
RDL.type MiniSat::Var, :initialize, '(MiniSat::Solver) -> MiniSat::Var'
RDL.type MiniSat::Solver, :<<, '(Array<MiniSat::Var>) -> %bot'
RDL.type MiniSat::Solver, :satisfied?, '() -> %bool'
RDL.type MiniSat::Solver, :solve, '() -> MiniSat::Model or false'

RDL.type AST, :s, '(RDL::Type::Type, Symbol, *TypedNode) -> TypedNode'
RDL.type TypedNode, :type, '() -> Symbol'
RDL.type TypedNode, :children, '() -> Array<TypedNode>'
RDL.type TypedNode, :to_sym, '() -> Symbol'

RDL.var_type BoolCond, :@conds, 'Array<TypedNode>'
RDL.var_type BoolCond, :@solver, 'MiniSat::Solver'
RDL.var_type BoolCond, :@intermediates, 'Hash<TypedNode, MiniSat::Var>'
RDL.type BoolCond, :conds, '() -> Array<TypedNode>'

RDL.type BoolCond, :<<, '(TypedNode) -> %any', typecheck: :later, wrap: false
RDL.type BoolCond, :positive?, '() -> %bool', typecheck: :later, wrap: false
RDL.type BoolCond, :negative?, '() -> %bool', typecheck: :later, wrap: false
RDL.type BoolCond, :to_ast, '() -> TypedNode', typecheck: :later, wrap: false
RDL.type BoolCond, :true?, '() -> %bool', typecheck: :later, wrap: false
RDL.type BoolCond, :inverse?, '(BoolCond) -> %bool', typecheck: :later, wrap: false
RDL.type BoolCond, :implies, '(BoolCond) -> %bool', typecheck: :later, wrap: false
RDL.type BoolCond, :strip_not, '(TypedNode) -> [TypedNode, Integer]', typecheck: :later, wrap: false
RDL.type BoolCond, :bool_vars, '(Array<TypedNode>) -> Array<MiniSat::Var>', typecheck: :later, wrap: false

RDL.type EffectAnalysis, 'self.effect_of', '(TypedNode, Hash<Symbol, RDL::Type::Type>, :read or :write) -> Array<String>'
RDL.type EffectAnalysis, 'self.type_of', '(TypedNode, Hash<Symbol, RDL::Type::Type>) -> RDL::Type::Type'

RDL.type EffectAnalysis, 'self.effect_leq', '(String, String) -> %bool', typecheck: :later, wrap: false
RDL.type EffectAnalysis, 'self.replace_self', '(Array<String>, String) -> Array<String>', typecheck: :later, wrap: false
RDL.type EffectAnalysis, 'self.has_self?', '(Array<String>) -> %bool', typecheck: :later, wrap: false
