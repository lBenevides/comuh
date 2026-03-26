class User < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :reactions, dependent: :destroy

  validates :username, presence: true, uniqueness: true
end
