class Message < ApplicationRecord
  belongs_to :user
  belongs_to :community
  belongs_to :parent_message
end
