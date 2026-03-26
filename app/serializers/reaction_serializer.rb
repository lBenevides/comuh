class ReactionSerializer
  REACTION_TYPES = %w[like love insightful].freeze

  def initialize(message)
    @message = message
  end

  def as_json(*)
    {
      message_id: @message.id,
      reactions: serialized_reactions
    }
  end

  private

  def serialized_reactions
    counts = @message.reactions.group(:reaction_type).count

    REACTION_TYPES.index_with { |type| counts[type] || 0 }
  end
end
