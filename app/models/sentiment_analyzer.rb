class SentimentAnalyzer
  POSITIVE_WORDS = [ "ótimo", "excelente", "legal", "bom", "adorei", "incrível" ]
  NEGATIVE_WORDS = [ "ruim", "péssimo", "horrível", "terrível", "odeio" ]

  def self.call(message, external: false)
    return legacy_score(message) unless external

    AISentimentAnalyzer.call(message)
  rescue StandardError => error
    Rails.logger.error(
      "[SentimentAnalyzer] external analyzer failed: #{error.class}: #{error.message}"
    )
    legacy_score(message)
  end

  def self.legacy_score(message)
    normalized_message = message.to_s.downcase

    positive = POSITIVE_WORDS.count { |word| normalized_message.include?(word) }
    negative = NEGATIVE_WORDS.count { |word| normalized_message.include?(word) }

    total = positive + negative
    return 0.0 if total.zero?

    ((positive - negative).to_f / total).round(2)
  end
end
