class GitlabNote < ApplicationRecord
  has_one :noteable, class_name: 'GitlabMergeRequest'
  has_one :in_reply_to, class_name: 'GitlabNote'

  def discussion_class
    GitlabDiscussion
  end
end

class GitlabMergeRequest < ApplicationRecord
end

class GitlabDiscussion < ApplicationRecord
  has_many :notes, class_name: 'GitlabNote'

  def first_note
    notes.first
  end

  # have to define these, because active record doesn't support has_many and has_one relationship in a single class
  def noteable
    GitlabMergeRequest.find_by_id(noteable_id)
  end
end
