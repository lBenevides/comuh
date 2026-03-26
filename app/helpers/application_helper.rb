module ApplicationHelper
  def reaction_counts_for(message)
    counts = message.reactions.each_with_object(Hash.new(0)) do |reaction, memo|
      memo[reaction.reaction_type] += 1
    end

    Reaction::REACTION_TYPES.index_with { |type| counts[type] || 0 }
  end

  def sentiment_label(score)
    return "Positive" if score.to_f > 0.2
    return "Negative" if score.to_f < -0.2

    "Neutral"
  end

  def sentiment_tone_class(score)
    return "sentiment-positive" if score.to_f > 0.2
    return "sentiment-negative" if score.to_f < -0.2

    "sentiment-neutral"
  end
end
