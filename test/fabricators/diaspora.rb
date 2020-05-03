Fabricator(:invitation_code, class_name: InvitationCode) do
  count { 3 }
end

Fabricator(:diaspora_user, class_name: DiasporaUser) do
  username { sequence(:user) { |i| "user_#{i}" } }
end
