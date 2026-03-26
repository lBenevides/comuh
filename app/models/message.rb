class Message < ApplicationRecord
  belongs_to :user
  belongs_to :community

  belongs_to :parent_message, class_name: 'Message', optional: true
  has_many :replies, class_name: 'Message', foreign_key: :parent_message_id, dependent: :destroy
  has_many :reactions, dependent: :destroy

  validates :content, presence: true
  validates :user_ip, presence: true
  validates :user, presence: true
  validates :community, presence: true

end
