# https://github.com/gitlabhq/gitlabhq/blob/13150a38e701080f6c64d4925c838214a3f5ef2c/spec/models/issue_spec.rb#L145-L158

require "test_helper"

describe "Gitlab" do
  it 'issue#close' do
    load_typedefs :stdlib, :active_record

    RDL.type Time, 'self.now', '() -> Time'
    RDL.type GitlabIssue, 'self.available_states', '() -> { opened: Integer, closed: Integer }'

    define :close, '(GitlabIssue) -> %bot', [GitlabIssue, Time] do
      spec "changes the state to closed" do
        pre {
          @issue = Fabricate(:issue)
          @prev_state = @issue.state_id
          close(@issue)
        }

        post { |result|
          assert { @prev_state == GitlabIssue.available_states[:opened] }
          assert { @issue.state_id == GitlabIssue.available_states[:closed] }
          assert { @issue.closed_at != nil }
        }
      end

      generate_program
    end
  end
end
