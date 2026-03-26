require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with a username" do
      user = described_class.new(username: "victor_boe")

      expect(user).to be_valid
    end

    it "requires a username" do
      user = described_class.new(username: nil)

      expect(user).not_to be_valid
      expect(user.errors.full_messages).to include("Username can't be blank")
    end

    it "requires a unique username" do
      described_class.create!(username: "victor_boe")
      duplicate_user = described_class.new(username: "victor_boe")

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors.full_messages).to include("Username has already been taken")
    end
  end
end
