Fabricator(:issue, class_name: GitlabIssue) do
  state_id { GitlabIssue.available_states[:opened] }
  closed_at { nil }
end
