# https://github.com/gitlabhq/gitlabhq/blob/13150a38e701080f6c64d4925c838214a3f5ef2c/spec/models/issue_spec.rb#L160-L175

require "test_helper"

describe "Gitlab" do
  it 'discussion#build' do
    load_typedefs :stdlib, :active_record
    RDL.type Array, :first, '() -> t', wrap: false
    RDL.type GitlabDiscussion, 'self.new', '() -> GitlabDiscussion', wrap: false
    RDL.type GitlabDiscussion, :noteable, '() -> GitlabMergeRequest', wrap: false, read: ['GitlabDiscussion']

    define :build, '(Array<GitlabNote>, GitlabMergeRequest) -> GitlabDiscussion', [GitlabDiscussion, GitlabMergeRequest, GitlabNote], prog_size: 30 do
      spec 'returns a discussion of the right type' do
        setup {
          @first_note = Fabricate(:diff_note_on_merge_request)
          @merge_request = @first_note.noteable
          second_note = Fabricate(:diff_note_on_merge_request, in_reply_to: @first_note)
          build([@first_note, second_note], @merge_request)
        }

        post { |discussion|
          assert { discussion.is_a? GitlabDiscussion }
          assert { discussion.notes.count == 2 }
          assert { discussion.first_note == @first_note }
          assert { discussion.noteable == @merge_request }
        }
      end

      generate_program
    end
  end
end
