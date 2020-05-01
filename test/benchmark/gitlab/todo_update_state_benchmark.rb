# https://github.com/gitlabhq/gitlabhq/blob/13150a38e701080f6c64d4925c838214a3f5ef2c/spec/models/todo_spec.rb#L376-L392

require "test_helper"

describe 'Gitlab' do
  it 'todo#update_state' do
    skip
    load_typedefs :stdlib, :ar_update

    RDL.type Symbol, :to_s, '() -> String', wrap: false
    RDL.type ActiveRecord::Base, 'self.where', "() -> ``DBTypes.array_schema(trec)``", wrap: false
    ActiveRecord_Relation.class_eval do
      extend RDL::Annotate

      type_params [:t], :dummy
      type :pluck, "(``DBTypes.pluck_input_type(trec)``) -> ``DBTypes.pluck_output_type(trec, targs)``", wrap: false
      type :not, "(``DBTypes.schema_type(trec)``) -> ``DBTypes.array_schema(trec)``", wrap: false
    end

    define :update_state, '(GitlabTodo, Symbol) -> Array<Integer>', [GitlabTodo], prog_size: 30 do
      spec 'updates the state of todos' do
        pre {
          @todo = GitlabTodo.create(state: :pending)
          ids = update_state(@todo, :done)
          @todo.reload
          ids
        }
        post { |result|
          assert { result == [@todo.id] }
          assert { @todo.state == 'done' }
        }
      end

      # spec 'does not update todos that already have the given state' do
      #   pre {
      #     @todo = GitlabTodo.create(state: :pending)
      #     update_state(@todo, :pending)
      #   }
      #   post { |result|
      #     assert { result.empty? }
      #   }
      # end

      generate_program
    end
  end
end
