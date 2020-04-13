class GitlabIssue < ApplicationRecord
  belongs_to :closed_by, class_name: 'GitlabUser'

  def self.available_states
    { opened: 0, closed: 1 }
  end

  def state=(s)
    s = s.to_sym
    self.state_id = GitlabIssue.available_states[s]
  end
end
