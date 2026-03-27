require "rails_helper"

RSpec.describe "Api::V1::Analytics", type: :request do
  describe "GET /api/v1/analytics/suspicious_ips" do
    let!(:first_user) { User.create!(username: "alice") }
    let!(:second_user) { User.create!(username: "bruno") }
    let!(:third_user) { User.create!(username: "carol") }
    let!(:fourth_user) { User.create!(username: "diego") }
    let!(:community) { Community.create!(name: "General") }

    before do
      Message.create!(
        user: first_user,
        community: community,
        content: "Message 1",
        user_ip: "10.0.0.1"
      )
      Message.create!(
        user: second_user,
        community: community,
        content: "Message 2",
        user_ip: "10.0.0.1"
      )
      Message.create!(
        user: third_user,
        community: community,
        content: "Message 3",
        user_ip: "10.0.0.1"
      )
      Message.create!(
        user: first_user,
        community: community,
        content: "Message 4",
        user_ip: "10.0.0.1"
      )

      Message.create!(
        user: first_user,
        community: community,
        content: "Message 5",
        user_ip: "10.0.0.2"
      )
      Message.create!(
        user: second_user,
        community: community,
        content: "Message 6",
        user_ip: "10.0.0.2"
      )

      Message.create!(
        user: fourth_user,
        community: community,
        content: "Message 7",
        user_ip: "10.0.0.3"
      )
    end

    it "returns suspicious ips with default minimum of distinct users" do
      get "/api/v1/analytics/suspicious_ips"

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body).to eq(
        "suspicious_ips" => [
          {
            "ip" => "10.0.0.1",
            "user_count" => 3,
            "usernames" => [ "alice", "bruno", "carol" ]
          }
        ]
      )
    end

    it "applies the requested min_users filter" do
      get "/api/v1/analytics/suspicious_ips", params: { min_users: 2 }

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["suspicious_ips"]).to contain_exactly(
        {
          "ip" => "10.0.0.1",
          "user_count" => 3,
          "usernames" => [ "alice", "bruno", "carol" ]
        },
        {
          "ip" => "10.0.0.2",
          "user_count" => 2,
          "usernames" => [ "alice", "bruno" ]
        }
      )
    end

    it "does not duplicate usernames from repeated messages on the same ip" do
      get "/api/v1/analytics/suspicious_ips", params: { min_users: 1 }

      expect(response).to have_http_status(:ok)

      suspicious_ip = JSON.parse(response.body)["suspicious_ips"].find do |entry|
        entry["ip"] == "10.0.0.1"
      end

      expect(suspicious_ip).to include(
        "user_count" => 3,
        "usernames" => [ "alice", "bruno", "carol" ]
      )
    end
  end
end
