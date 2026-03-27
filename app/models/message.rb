class Message < ApplicationRecord
  belongs_to :user
  belongs_to :community

  belongs_to :parent_message, class_name: "Message", optional: true, inverse_of: :replies
  has_many :replies, class_name: "Message", foreign_key: :parent_message_id, dependent: :destroy, inverse_of: :parent_message
  has_many :reactions, dependent: :destroy

  after_create_commit :broadcast_message

  validates :content, presence: true
  validates :user_ip, presence: true
  validates :user, presence: true
  validates :community, presence: true

  private

  def broadcast_message
    if parent_message_id.present?
      broadcast_append_to(
        parent_message,
        target: "thread-replies",
        partial: "messages/thread_message",
        locals: { message: self, depth: 1 }
      )
    else
      broadcast_prepend_to(
        community,
        target: "community-message-list",
        partial: "messages/message_card",
        locals: { message: self, context: :community }
      )

      broadcast_replace_to(
        "communities",
        target: ActionView::RecordIdentifier.dom_id(community),
        partial: "communities/community_card",
        locals: { community: community_with_messages_count }
      )
    end
  end

  def community_with_messages_count
    Community
      .left_joins(:messages)
      .select("communities.*, COUNT(messages.id) AS messages_count")
      .group("communities.id")
      .find(community_id)
  end
end
