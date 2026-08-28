class Poll < ActiveRecord::Base
  belongs_to :project
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :options, class_name: 'PollOption', dependent: :destroy
  has_many :votes, class_name: 'PollVote', dependent: :destroy

  accepts_nested_attributes_for :options, allow_destroy: true

  validates :title, presence: true

  def voted_by?(user)
    votes.where(user_id: user.id).exists?
  end
end
