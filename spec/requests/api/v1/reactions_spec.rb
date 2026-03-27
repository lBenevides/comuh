require "rails_helper"

RSpec.describe "Api::V1::Reactions", type: :request do
  describe "POST /api/v1/reactions" do
    let!(:community) { Community.create!(name: "General") }
    let!(:user) { User.create!(username: "victor_boe") }
    let!(:other_user) { User.create!(username: "alice") }
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

    it "returns aggregated counts including existing reactions from other users and types" do
      Reaction.create!(message: message, user: other_user, reaction_type: "like")
      Reaction.create!(message: message, user: other_user, reaction_type: "love")

      post "/api/v1/reactions", params: payload

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body).to eq(
        "message_id" => message.id,
        "reactions" => {
          "like" => 2,
          "love" => 1,
          "insightful" => 0
        }
      )
    end

    it "allows the same user to react with a different reaction type" do
      Reaction.create!(message: message, user: user, reaction_type: "like")

      expect do
        post "/api/v1/reactions", params: payload.merge(reaction_type: "love")
      end.to change(Reaction, :count).by(1)

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body).to eq(
        "message_id" => message.id,
        "reactions" => {
          "like" => 1,
          "love" => 1,
          "insightful" => 0
        }
      )
    end

    it "returns conflict when the same user repeats the same reaction type" do
      Reaction.create!(message: message, user: user, reaction_type: "like")

      expect do
        post "/api/v1/reactions", params: payload
      end.not_to change(Reaction, :count)

      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)).to eq(
        "errors" => ["Usuario ja adicionou essa reacao nesta mensagem"]
      )
    end

    it "returns not found when message does not exist" do
      post "/api/v1/reactions", params: payload.merge(message_id: -1)

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq(
        "error" => "Mensagem nao encontrada"
      )
    end

    it "returns not found when user does not exist" do
      post "/api/v1/reactions", params: payload.merge(user_id: -1)

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq(
        "error" => "Usuario nao encontrado"
      )
    end

    it "creates a reaction when identifying the user by username" do
      expect do
        post "/api/v1/reactions", params: payload.except(:user_id).merge(username: "bia")
      end.to change(Reaction, :count).by(1)
        .and change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        "message_id" => message.id,
        "reactions" => {
          "like" => 1,
          "love" => 0,
          "insightful" => 0
        }
      )
    end

    it "returns unprocessable content when username is invalid" do
      invalid_user = User.new(username: nil)
      invalid_user.valid?

      allow(User).to receive(:find_or_create_by).and_return(invalid_user)

      post "/api/v1/reactions", params: payload.except(:user_id).merge(username: "bia")

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to eq(
        "errors" => ["Usuario nao pode ficar em branco"]
      )
    end

    it "returns unprocessable entity for invalid reaction type" do
      post "/api/v1/reactions", params: payload.merge(reaction_type: "haha")

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to eq(
        "errors" => ["Tipo de reacao nao esta incluido na lista"]
      )
    end

    it "returns unprocessable content when reaction_type is missing" do
      post "/api/v1/reactions", params: payload.except(:reaction_type)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to eq(
        "errors" => [
          "Tipo de reacao nao pode ficar em branco",
          "Tipo de reacao nao esta incluido na lista"
        ]
      )
    end

    it "returns conflict when the insert hits a uniqueness race" do
      allow_any_instance_of(Reaction).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

      post "/api/v1/reactions", params: payload

      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)).to eq(
        "errors" => ["Usuario ja adicionou essa reacao nesta mensagem"]
      )
    end
  end
end
