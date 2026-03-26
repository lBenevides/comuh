class Reaction < ApplicationRecord
  REACTION_TYPES = %w[like love insightful].freeze

  belongs_to :message
  belongs_to :user

  validates :reaction_type, presence: true
  validates :reaction_type, inclusion: { in: REACTION_TYPES }
  validates :user_id, uniqueness: { scope: [:message_id, :reaction_type], message: "has already added this reaction to this message" }
end
