class Reaction < ApplicationRecord
  REACTION_TYPES = %w[like love insightful].freeze

  belongs_to :message
  belongs_to :user

  after_create_commit :broadcast_reaction_update

  validates :reaction_type, presence: true
  validates :reaction_type, inclusion: { in: REACTION_TYPES }
  validates :user_id, uniqueness: { scope: [ :message_id, :reaction_type ], message: :already_reacted }

  private

  def broadcast_reaction_update
    broadcast_replace_to(
      [ message, :community ],
      target: "message-#{message.id}",
      partial: "messages/message_card",
      locals: { message: message.reload, context: :community }
    )

    broadcast_replace_to(
      [ message, :thread ],
      target: "message-#{message.id}",
      partial: "messages/message_card",
      locals: { message: message, context: :thread }
    )
  end
end
