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
      expect(reaction.errors.full_messages).to include("Tipo de reação não pode ficar em branco")
    end

    it "rejects unsupported reaction types" do
      reaction = described_class.new(message: message, user: user, reaction_type: "haha")

      expect(reaction).not_to be_valid
      expect(reaction.errors.full_messages).to include("Tipo de reação não está incluído na lista")
    end

    it "prevents the same user from repeating the same reaction type on a message" do
      described_class.create!(message: message, user: user, reaction_type: "like")
      duplicate_reaction = described_class.new(message: message, user: user, reaction_type: "like")

      expect(duplicate_reaction).not_to be_valid
      expect(duplicate_reaction.errors.full_messages).to include(
        "Usuário já adicionou essa reação nesta mensagem"
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

  describe "database constraints" do
    it "has a unique index for message, user, and reaction type" do
      indexes = ActiveRecord::Base.connection.indexes(:reactions)
      unique_index = indexes.find { |index| index.name == "index_reactions_on_message_user_and_type" }

      expect(unique_index).to be_present
      expect(unique_index.unique).to be(true)
      expect(unique_index.columns).to eq(%w[message_id user_id reaction_type])
    end
  end
end
