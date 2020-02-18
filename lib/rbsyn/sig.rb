RDL.type Proc, :initialize, '() { (%any) -> %any } -> Proc'
RDL.type RDL::Globals, 'self.types', '() -> Hash<Symbol, RDL::Type::Type>'
RDL.type RDL::Type::Type, :<=, '(RDL::Type::Type) -> %bool'
RDL.type MiniSat::Var, :-@, '() -> MiniSat::Var'
RDL.type MiniSat::Var, :initialize, '(MiniSat::Solver) -> MiniSat::Var'
RDL.type MiniSat::Solver, :<<, '(Array<MiniSat::Var>) -> %bot'
RDL.type MiniSat::Solver, :satisfied?, '() -> %bool'
RDL.type MiniSat::Solver, :solve, '() -> MiniSat::Model or false'
RDL.type ::AST::Processor, :process, '(TypedNode) -> TypedNode'

RDL.type AST, :s, '(RDL::Type::Type, Symbol, *TypedNode) -> TypedNode'
RDL.type AST, :s, '(RDL::Type::Type, :hole, Integer, %any) -> TypedNode'
RDL.type AST, :s, '(RDL::Type::Type, :envref, Integer) -> TypedNode'
RDL.type AST, :s, '(RDL::Type::Type, :send, TypedNode, Symbol, *TypedNode) -> TypedNode'
RDL.type AST, :eval_ast, '(Context, TypedNode, Proc) -> [%any, Class]'
RDL.type TypedNode, :type, '() -> Symbol'
RDL.type TypedNode, :ttype, '() -> RDL::Type::Type'
RDL.type TypedNode, :children, '() -> Array<TypedNode>'
RDL.type TypedNode, :to_sym, '() -> Symbol'
RDL.type TypedNode, :to_ast, '() -> TypedNode'

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

RDL.type BranchCountElimination, 'self.eliminate', '(Array<ProgTuple>) -> Array<ProgTuple>', typecheck: :later, wrap: false
RDL.type BranchCountElimination, 'self.count_branches', '(ProgTuple) -> Integer', typecheck: :later, wrap: false
RDL.type DuplicateElimiation, 'self.eliminate', '(Array<ProgTuple>) -> Array<ProgTuple>', typecheck: :later, wrap: false

RDL.var_type LocalEnvironment, :@@ref, 'Integer'
RDL.var_type LocalEnvironment, :@info, 'Hash<RDL::Type::Type, Array<{ expr: TypedNode, count: Integer, ref: Integer }>>'
RDL.type LocalEnvironment, :info, '() -> Hash<RDL::Type::Type, Array<{ expr: TypedNode, count: Integer, ref: Integer }>>'

RDL.type LocalEnvironment, :next_ref, '() -> Integer', typecheck: :later, wrap: false
RDL.type LocalEnvironment, :bump_count, '(Integer) -> %any', typecheck: :later, wrap: false
RDL.type LocalEnvironment, :get_expr, '(RDL::Type::Type, Integer) -> { expr: TypedNode, count: Integer, ref: Integer }', typecheck: :later, wrap: false
RDL.type LocalEnvironment, :add_expr, '(TypedNode) -> Integer', typecheck: :later, wrap: false
RDL.type LocalEnvironment, :exprs_with_type, '(RDL::Type::Type) -> Array<Integer>', typecheck: :later, wrap: false
RDL.type LocalEnvironment, :+, '(LocalEnvironment) -> LocalEnvironment', typecheck: :later, wrap: false

RDL.var_type ProgTuple, :@ctx, 'Context'
RDL.var_type ProgTuple, :@branch, 'BoolCond'
RDL.var_type ProgTuple, :@prog, 'ProgWrapper or Array<ProgTuple>'
RDL.var_type ProgTuple, :@preconds, 'Array<Proc>'
RDL.type ProgTuple, :prog, '() -> ProgWrapper or Array<ProgTuple>'
RDL.type ProgTuple, :branch, '() -> BoolCond'
RDL.type ProgTuple, :preconds, '() -> Array<Proc>'
RDL.type ProgTuple, :speculate_opposite_branch, '(Array<TypedNode>, Array<Proc>, Array<Proc>) -> Array<TypedNode>'

RDL.type ProgTuple, :initialize, '(Context, ProgWrapper or Array<ProgTuple>, BoolCond or TypedNode, Array<Proc>) -> self', typecheck: :later, wrap: false
RDL.type ProgTuple, :==, '(ProgTuple) -> %bool', typecheck: :later, wrap: false
RDL.type ProgTuple, :eql?, '(ProgTuple) -> %bool', typecheck: :later, wrap: false
RDL.type ProgTuple, :hash, '() -> Integer', typecheck: :later, wrap: false
RDL.type ProgTuple, :+, '(ProgTuple) -> Array<ProgTuple>', typecheck: :later, wrap: false
RDL.type ProgTuple, :to_ast, '() -> TypedNode', typecheck: :later, wrap: false
RDL.type ProgTuple, :merge_impl, '(ProgTuple, ProgTuple) -> Array<ProgTuple>', typecheck: :later, wrap: false

RDL.var_type ProgWrapper, :@env, 'LocalEnvironment'
RDL.var_type ProgWrapper, :@seed, 'TypedNode'
RDL.var_type ProgWrapper, :@exprs, 'Array<TypedNode>'
RDL.type ProgWrapper, :ttype, '() -> RDL::Type::Type'
RDL.type ProgWrapper, :to_ast, '() -> TypedNode'
RDL.type ProgWrapper, :initialize, '(Context, TypedNode, LocalEnvironment) -> self'
RDL.type ProgWrapper, :look_for, '(:type or :effect or :teffect, RDL::Type::Type or Array<String>) -> %any'

RDL.type SynHelper, :generate, '(ProgWrapper, Array<Proc>, Array<Proc>, %bool) -> Array<TypedNode>'

RDL.type FlattenProgramPass, :initialize, '(LocalEnvironment) -> self'