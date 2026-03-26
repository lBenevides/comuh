require "rails_helper"

RSpec.describe Message, type: :model do
  let!(:user) { User.create!(username: "victor_boe") }
  let!(:community) { Community.create!(name: "General") }

  describe "validations" do
    it "is valid with the required attributes" do
      message = described_class.new(
        user: user,
        community: community,
        content: "Hello world",
        user_ip: "192.168.1.1"
      )

      expect(message).to be_valid
    end

    it "requires content" do
      message = described_class.new(user: user, community: community, content: nil, user_ip: "192.168.1.1")

      expect(message).not_to be_valid
      expect(message.errors.full_messages).to include("Content can't be blank")
    end

    it "requires user_ip" do
      message = described_class.new(user: user, community: community, content: "Hello world", user_ip: nil)

      expect(message).not_to be_valid
      expect(message.errors.full_messages).to include("User ip can't be blank")
    end

    it "requires a user" do
      message = described_class.new(community: community, content: "Hello world", user_ip: "192.168.1.1")

      expect(message).not_to be_valid
      expect(message.errors.full_messages).to include("User can't be blank")
    end

    it "requires a community" do
      message = described_class.new(user: user, content: "Hello world", user_ip: "192.168.1.1")

      expect(message).not_to be_valid
      expect(message.errors.full_messages).to include("Community can't be blank")
    end
  end

  describe "reply relationships" do
    it "supports replies through parent_message" do
      parent_message = described_class.create!(
        user: user,
        community: community,
        content: "Parent",
        user_ip: "192.168.1.1"
      )

      reply = described_class.create!(
        user: user,
        community: community,
        parent_message: parent_message,
        content: "Reply",
        user_ip: "192.168.1.2"
      )

      expect(reply.parent_message).to eq(parent_message)
      expect(parent_message.replies).to contain_exactly(reply)
    end
  end
end
