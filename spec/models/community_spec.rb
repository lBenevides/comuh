require "rails_helper"

RSpec.describe Community, type: :model do
  describe "validations" do
    it "is valid with a name" do
      community = described_class.new(name: "General")

      expect(community).to be_valid
    end

    it "requires a name" do
      community = described_class.new(name: nil)

      expect(community).not_to be_valid
      expect(community.errors.full_messages).to include("Name can't be blank")
    end

    it "requires a unique name" do
      described_class.create!(name: "General")
      duplicate_community = described_class.new(name: "General")

      expect(duplicate_community).not_to be_valid
      expect(duplicate_community.errors.full_messages).to include("Name has already been taken")
    end
  end
end
