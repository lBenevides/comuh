require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#reaction_counts_for" do
    it "returns counts for all supported reaction types" do
      message = instance_double("Message", reactions: [
        instance_double("Reaction", reaction_type: "like"),
        instance_double("Reaction", reaction_type: "like"),
        instance_double("Reaction", reaction_type: "insightful")
      ])

      expect(helper.reaction_counts_for(message)).to eq(
        "like" => 2,
        "love" => 0,
        "insightful" => 1
      )
    end
  end

  describe "#sentiment_label" do
    it "returns the negative translation for low scores" do
      expect(helper.sentiment_label(-0.3)).to eq("Negativo")
    end

    it "returns the neutral translation for mid-range scores" do
      expect(helper.sentiment_label(0.0)).to eq("Neutro")
    end
  end

  describe "#sentiment_tone_class" do
    it "returns the negative css class for low scores" do
      expect(helper.sentiment_tone_class(-0.3)).to eq("sentiment-negative")
    end

    it "returns the neutral css class for mid-range scores" do
      expect(helper.sentiment_tone_class(0.0)).to eq("sentiment-neutral")
    end
  end
end
