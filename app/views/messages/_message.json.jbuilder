json.extract! message, :id, :message, :user_name, :created_at, :updated_at
json.url message_url(message, format: :json)
