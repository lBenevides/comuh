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
  end
end
