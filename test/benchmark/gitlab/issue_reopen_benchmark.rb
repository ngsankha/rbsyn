# https://github.com/gitlabhq/gitlabhq/blob/13150a38e701080f6c64d4925c838214a3f5ef2c/spec/models/issue_spec.rb#L160-L175

require "test_helper"

describe "Gitlab" do
  it 'issue#reopen' do
    load_typedefs :stdlib, :active_record

    RDL.type Time, 'self.now', '() -> Time'
    RDL.type GitlabIssue, 'self.available_states', '() -> { opened: Integer, closed: Integer }'

    define :reopen, '(GitlabIssue) -> %bot', [GitlabIssue, Time], enable_nil: true do
      spec "changes the state to closed" do
        setup {
          @user = Fabricate(:gitlab_user)
          @issue = Fabricate(:issue, state: 'closed', closed_at: Time.now, closed_by: @user)
          @prev_state = @issue.state_id
          @prev_user = @issue.closed_by
          reopen(@issue)
        }

        post { |result|
          assert { @issue.closed_at == nil }
          assert { @prev_user == @user }
          assert { @issue.closed_by == nil }
          assert { @prev_state == GitlabIssue.available_states[:closed] }
          assert { @issue.state_id == GitlabIssue.available_states[:opened] }
        }
      end

      generate_program
    end
  end
end
