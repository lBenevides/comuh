require "rails_helper"

RSpec.describe Reaction, type: :model do
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

  describe "validations" do
    it "is valid with an allowed reaction_type" do
      reaction = described_class.new(message: message, user: user, reaction_type: "like")

      expect(reaction).to be_valid
    end

    it "requires a reaction_type" do
      reaction = described_class.new(message: message, user: user, reaction_type: nil)

      expect(reaction).not_to be_valid
      expect(reaction.errors.full_messages).to include("Tipo de reacao nao pode ficar em branco")
    end

    it "rejects unsupported reaction types" do
      reaction = described_class.new(message: message, user: user, reaction_type: "haha")

      expect(reaction).not_to be_valid
      expect(reaction.errors.full_messages).to include("Tipo de reacao nao esta incluido na lista")
    end

    it "prevents the same user from repeating the same reaction type on a message" do
      described_class.create!(message: message, user: user, reaction_type: "like")
      duplicate_reaction = described_class.new(message: message, user: user, reaction_type: "like")

      expect(duplicate_reaction).not_to be_valid
      expect(duplicate_reaction.errors.full_messages).to include(
        "Usuario ja adicionou essa reacao nesta mensagem"
      )
    end

    it "allows different users to use the same reaction type on a message" do
      described_class.create!(message: message, user: user, reaction_type: "like")
      second_reaction = described_class.new(message: message, user: other_user, reaction_type: "like")

      expect(second_reaction).to be_valid
    end

    it "allows the same user to use a different reaction type on a message" do
      described_class.create!(message: message, user: user, reaction_type: "like")
      second_reaction = described_class.new(message: message, user: user, reaction_type: "love")

      expect(second_reaction).to be_valid
    end
  end
end
