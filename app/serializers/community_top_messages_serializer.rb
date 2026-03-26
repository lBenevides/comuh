class CommunityTopMessagesSerializer
  def initialize(messages)
    @messages = messages
  end

  def as_json(*)
    {
      messages: @messages.map do |message|
        {
          id: message.id,
          content: message.content,
          user: {
            id: message.user.id,
            username: message.user.username
          },
          ai_sentiment_score: message.ai_sentiment_score,
          reaction_count: message.read_attribute(:reaction_count).to_i,
          reply_count: message.read_attribute(:reply_count).to_i,
          engagement_score: message.read_attribute(:engagement_score).to_f
        }
      end
    }
  end
end
