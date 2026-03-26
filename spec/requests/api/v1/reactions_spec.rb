require "rails_helper"

RSpec.describe "Api::V1::Reactions", type: :request do
  describe "POST /api/v1/reactions" do
    let!(:community) { Community.create!(name: "General") }
    let!(:user) { User.create!(username: "victor_boe") }
    let!(:message) do
      Message.create!(
        user: user,
        community: community,
        content: "Primeira mensagem",
        user_ip: "192.168.1.1"
      )
    end

    let(:payload) do
      {
        message_id: message.id,
        user_id: user.id,
        reaction_type: "like"
      }
    end

    it "creates a reaction and returns aggregated counts" do
      expect do
        post "/api/v1/reactions", params: payload
      end.to change(Reaction, :count).by(1)

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body).to eq(
        "message_id" => message.id,
        "reactions" => {
          "like" => 1,
          "love" => 0,
          "insightful" => 0
        }
      )
    end

    it "returns conflict when the reaction already exists" do
      Reaction.create!(message: message, user: user, reaction_type: "like")

      expect do
        post "/api/v1/reactions", params: payload
      end.not_to change(Reaction, :count)

      expect(response).to have_http_status(:conflict)
    end

    it "returns not found when message does not exist" do
      post "/api/v1/reactions", params: payload.merge(message_id: -1)

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found when user does not exist" do
      post "/api/v1/reactions", params: payload.merge(user_id: -1)

      expect(response).to have_http_status(:not_found)
    end

    it "returns unprocessable entity for invalid reaction type" do
      post "/api/v1/reactions", params: payload.merge(reaction_type: "haha")

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
