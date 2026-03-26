require "rails_helper"

RSpec.describe "Frontend pages", type: :request do
  let!(:community) do
    Community.create!(name: "General", description: "Main community")
  end
  let!(:user) { User.create!(username: "victor_boe") }
  let!(:message) do
    Message.create!(
      user: user,
      community: community,
      content: "Frontend ready",
      user_ip: "192.168.1.1",
      ai_sentiment_score: 0.8
    )
  end

  it "renders the communities home page" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Comunidades com pulso")
    expect(response.body).to include("General")
  end

  it "renders the community timeline" do
    get "/communities/#{community.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Frontend ready")
    expect(response.body).to include("Iniciar nova thread")
  end

  it "renders the message detail page" do
    get "/messages/#{message.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Mensagem principal e respostas")
    expect(response.body).to include("Frontend ready")
  end

  it "renders the home page in english when locale=en" do
    get "/", params: { locale: "en" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Communities with pulse")
  end
end
