require "rails_helper"

RSpec.describe "Api::V1::Messages", type: :request do
  describe "POST /api/v1/messages" do
    let!(:community) { Community.create!(name: "General") }
    let(:payload) do
      {
        username: "victor_boe",
        community_id: community.id,
        content: "otimo",
        user_ip: "192.168.1.1",
        parent_message_id: nil
      }
    end

    before do
      allow(SentimentAnalyzer).to receive(:call).and_return(0.75)
    end

    it "creates a message and returns the serialized payload" do
      expect do
        post "/api/v1/messages", params: payload
      end.to change(Message, :count).by(1)
        .and change(User, :count).by(1)

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)

      expect(body).to include(
        "content" => "otimo",
        "community_id" => community.id,
        "parent_message_id" => nil,
        "ai_sentiment_score" => 0.75
      )
      expect(body["user"]).to include(
        "username" => "victor_boe"
      )
    end

    it "returns an error when username is invalid" do
      post "/api/v1/messages", params: payload.merge(username: nil)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to eq(
        "errors" => [ "Usuario nao pode ficar em branco" ]
      )
    end

    it "returns not found when community does not exist" do
      post "/api/v1/messages", params: payload.merge(community_id: -1)

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq(
        "error" => "Comunidade nao encontrada"
      )
    end

    it "returns validation errors when content is missing" do
      post "/api/v1/messages", params: payload.merge(content: nil)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to eq(
        "errors" => [ "Conteudo nao pode ficar em branco" ]
      )
    end

    it "uses the request ip when user_ip is missing" do
      post "/api/v1/messages", params: payload.merge(user_ip: nil)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to include(
        "content" => "otimo"
      )
      expect(Message.order(:id).last.user_ip).to be_present
    end

    it "does not continue the flow after rendering community not found" do
      expect(SentimentAnalyzer).not_to receive(:call)

      post "/api/v1/messages", params: payload.merge(community_id: -1)

      expect(response).to have_http_status(:not_found)
    end
  end
end
