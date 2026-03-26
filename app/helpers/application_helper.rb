module ApplicationHelper
  def reaction_counts_for(message)
    counts = message.reactions.each_with_object(Hash.new(0)) do |reaction, memo|
      memo[reaction.reaction_type] += 1
    end

    Reaction::REACTION_TYPES.index_with { |type| counts[type] || 0 }
  end

  def sentiment_label(score)
    return t("messages.card.sentiment.positive") if score.to_f > 0.2
    return t("messages.card.sentiment.negative") if score.to_f < -0.2

    t("messages.card.sentiment.neutral")
  end

  def sentiment_tone_class(score)
    return "sentiment-positive" if score.to_f > 0.2
    return "sentiment-negative" if score.to_f < -0.2

    "sentiment-neutral"
  end

  def message_timestamp(timestamp)
    l(timestamp, format: :message_card)
  end

  def reaction_label(reaction_type)
    t("messages.reactions.types.#{reaction_type}")
  end

  def locale_switch_url(locale)
    url_for(locale: locale)
  end
end
