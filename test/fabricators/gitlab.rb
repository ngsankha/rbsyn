Fabricator(:issue, class_name: GitlabIssue) do
  state { :opened }
  closed_at { nil }
  closed_by { nil }
end

Fabricator(:gitlab_user, class_name: GitlabUser) do
end
