require "rails_helper"

RSpec.describe "Api::V1::Communities", type: :request do
  describe "GET /api/v1/communities/:id/messages/top" do
    let!(:community) { Community.create!(name: "General") }
    let!(:other_community) { Community.create!(name: "Random") }
    let!(:author) { User.create!(username: "author") }
    let!(:other_user) { User.create!(username: "other_user") }
    let!(:third_user) { User.create!(username: "third_user") }

    let!(:top_message) do
      Message.create!(
        user: author,
        community: community,
        content: "Top message",
        user_ip: "192.168.1.1",
        ai_sentiment_score: 0.9,
        created_at: 2.hours.ago
      )
    end

    let!(:second_message) do
      Message.create!(
        user: author,
        community: community,
        content: "Second message",
        user_ip: "192.168.1.2",
        ai_sentiment_score: 0.4,
        created_at: 1.hour.ago
      )
    end

    let!(:other_community_message) do
      Message.create!(
        user: other_user,
        community: other_community,
        content: "Other community",
        user_ip: "192.168.1.3"
      )
    end

    before do
      Reaction.create!(message: top_message, user: author, reaction_type: "like")
      Reaction.create!(message: top_message, user: other_user, reaction_type: "love")

      Message.create!(
        user: other_user,
        community: community,
        parent_message: top_message,
        content: "Reply 1",
        user_ip: "192.168.1.4"
      )
      Message.create!(
        user: third_user,
        community: community,
        parent_message: top_message,
        content: "Reply 2",
        user_ip: "192.168.1.5"
      )

      Reaction.create!(message: second_message, user: other_user, reaction_type: "insightful")
    end

    it "returns community messages ranked by engagement score" do
      get "/api/v1/communities/#{community.id}/messages/top"

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["messages"].size).to eq(4)
      expect(body["messages"].first).to include(
        "id" => top_message.id,
        "content" => "Top message",
        "ai_sentiment_score" => 0.9,
        "reaction_count" => 2,
        "reply_count" => 2,
        "engagement_score" => 5.0
      )
      expect(body["messages"].first["user"]).to include(
        "id" => author.id,
        "username" => "author"
      )

      expect(body["messages"].second).to include(
        "id" => second_message.id,
        "reaction_count" => 1,
        "reply_count" => 0,
        "engagement_score" => 1.5
      )

      returned_ids = body["messages"].map { |message| message["id"] }
      expect(returned_ids).not_to include(other_community_message.id)
    end

    it "applies the requested limit" do
      get "/api/v1/communities/#{community.id}/messages/top", params: { limit: 1 }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["messages"].size).to eq(1)
    end

    it "caps the limit at 50" do
      get "/api/v1/communities/#{community.id}/messages/top", params: { limit: 999 }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["messages"].size).to eq(4)
    end

    it "returns not found when the community does not exist" do
      get "/api/v1/communities/-1/messages/top"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq(
        "error" => "Community not found"
      )
    end
  end
end
