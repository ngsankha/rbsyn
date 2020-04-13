class GitlabIssue < ApplicationRecord
  def self.available_states
    { opened: 0, closed: 1 }
  end
end
