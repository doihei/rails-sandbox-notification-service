class Notification < ApplicationRecord
  validates :article_id, presence: true
  validates :message, presence: true
  validates :user_id, presence: true

  scope :unread, -> { where(read: false) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
end
