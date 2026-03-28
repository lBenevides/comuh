require "rails_helper"

RSpec.describe SentimentAnalyzer do
  describe ".call" do
    it "returns a positive score when positive keywords are present" do
      expect(described_class.call("Conteudo otimo e legal")).to eq(1.0)
    end

    it "returns a negative score when negative keywords are present" do
      expect(described_class.call("Conteudo ruim e terrível")).to eq(-1.0)
    end

    it "returns a neutral score when there are no known keywords" do
      expect(described_class.call("Mensagem comum sem polaridade")).to eq(0.0)
    end

    it "balances positive and negative keywords" do
      expect(described_class.call("ótimo, mas também ruim")).to eq(0.0)
    end

    it "matches keywords regardless of letter case" do
      expect(described_class.call("INCRÍVEL e BOM")).to eq(1.0)
    end

    it "does not mutate the original string" do
      message = "Ótimo Conteúdo"

      described_class.call(message)

      expect(message).to eq("Ótimo Conteúdo")
    end

    it "uses the AI analyzer when external is true" do
      allow(AISentimentAnalyzer).to receive(:call).with("Mensagem externa").and_return(0.61)

      expect(described_class.call("Mensagem externa", external: true)).to eq(0.61)
    end

    it "falls back to the legacy analyzer when the AI analyzer fails" do
      allow(AISentimentAnalyzer).to receive(:call).with("Conteudo otimo e legal").and_raise(StandardError)

      expect(described_class.call("Conteudo otimo e legal", external: true)).to eq(1.0)
    end
  end
end
