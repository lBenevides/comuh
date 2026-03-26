class SentimentAnalyzer
  POSITIVE_WORDS = ['ótimo', 'excelente', 'legal', 'bom', 'adorei', 'incrível']
  NEGATIVE_WORDS = ['ruim', 'péssimo', 'horrível', 'terrível', 'odeio']

  def self.call(message)
    normalized_message = message.to_s.downcase

    positive = POSITIVE_WORDS.count { |word| normalized_message.include?(word) }
    negative = NEGATIVE_WORDS.count { |word| normalized_message.include?(word) }

    total = positive + negative
    return 0.0 if total.zero?

    ((positive - negative).to_f / total).round(2)
  end
end
