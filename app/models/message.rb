class Message < ApplicationRecord
  validates :content, :role, :session_id, presence: true
end
