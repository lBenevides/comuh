require "rails_helper"

RSpec.describe AISentimentAnalyzer do
  describe ".call" do
    it "returns a normalized score from the Gemini response" do
      response = instance_double(
        Net::HTTPSuccess,
        body: { candidates: [ { content: { parts: [ { text: "0.82" } ] } } ] }.to_json
      )
      http_client = class_double(Net::HTTP)

      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(http_client).to receive(:post).and_return(response)

      analyzer = described_class.new(api_key: "test-key", http_client: http_client)

      expect(analyzer.call("Mensagem muito boa")).to eq(0.82)
    end

    it "clamps scores outside the accepted range" do
      response = instance_double(
        Net::HTTPSuccess,
        body: { candidates: [ { content: { parts: [ { text: "5.0" } ] } } ] }.to_json
      )
      http_client = class_double(Net::HTTP)

      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(http_client).to receive(:post).and_return(response)

      analyzer = described_class.new(api_key: "test-key", http_client: http_client)

      expect(analyzer.call("Mensagem excelente")).to eq(1.0)
    end
  end
end
