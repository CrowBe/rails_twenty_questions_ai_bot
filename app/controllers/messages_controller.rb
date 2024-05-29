class MessagesController < ApplicationController
  before_action :check_authenticated

  # GET /messages or /messages.json
  def index
    @messages = Message.where(session_id: session_id).order(created_at: :desc)
  end

  # TODO: Consider setting up two separate functions that initialize our chat, including system prompt. And another one that continues on an existing chat that's passed in
  # POST /messages or /messages.json
  def create
    Message.transaction do
      begin
        # Get number of messages
        chat_session = session[:chat_session]
        chat_history = session[:chat_history] || []
        num_questions = (session[:num_questions] || -1)
        # This should only happen the first time you log in and play, until you quit
        if chat_session.blank?
          questions_left = 20-num_questions
          # Open up the service session and pass in the system prompt
          chat_session = ChatService.new(initial_prompt: "You are a competitive bot that plays 20 questions with a user. 
          If #{num_questions} < 1 then you have not yet started the game, answer the user with: 
          'Let's play 20 questions! Think of something, and I will try my best to guess it within 20 questions, when you have a word let me know.'. 
          Once the user says they are ready, start asking questions. Remember you are only allowed to ask yes or no questions. 
          If #{num_questions} is between 2 and 20 then you are in a game already and you have #{questions_left} questions left. 
          Remember to check the chat history to help you narrow down what the user might be thinking of.
          Remember to start off with broader questions and once you hone into a category or topic, don't get too specific until you are pretty sure.
          Do not ask anything obscene, grotesque or anything to do with profanity or adult themes. 
          If #{num_questions}= 20 and you have not yet guessed the correct word, you lose. 
          State that you have lost and the game is over and ask them to clear the chat if they want to play another game.
          If you have guessed the correct word and #{num_questions} < 20 then state that you have won and ask them if they want to play again by clearing the chat. ")
        end
        # This should happen the first time you play, and every time you restart the game
        if chat_history.blank?
          chat_history = [chat_session.system_prompt]
          Message.all.order(:created_at).each do |msg|
            chat_history << {
              role: msg.role,
              content: msg.content
            }
          end
        end

        # Create a database record of the newest message
        user_message = Message.new(message_params)
        user_message.role = "user"
        user_message.session_id = session_id
        # Throw on failed message save - to be caught by rescue
        user_message.save!
        # Get all messages that exist in the db from the current session, loop through and insert them into our chat history variable
        chat_history << {
          role: user_message.role,
          content: user_message.content
        }
        
        # Call the chat service and pass in the chat history then add the response to the database record
        response = chat_session.call(chat_history:)
        ai_message = Message.new(role: "assistant", session_id: session_id, content: response)
        ai_message.save!
        chat_history << {
          role: ai_message.role,
          content: ai_message.content
        }
        # Increment our questions asked in session
        session[:num_questions] = num_questions.to_i + 1
        # If we get here we have successfully created a message and a reply and saved them so return to the chat screen with a fresh list of messages
        @messages = Message.where(session_id: session_id).order(created_at: :desc)
        redirect_to messages_url(@messages), notice: "Message was successfully created."
      
        # rescue failed message save and raise error, undo user message create as well
      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback
        render :new, status: :unprocessable_entity
      end
    end
  end

  # function to destroy every message in the database (clear chat history)
  def destroy_all
    Message.transaction do
      begin
        # From database get all messages and loop through each and call destroy!
        Message.all.each(&:destroy!)
        session[:num_questions] = 0
        session[:chat_history] = []
        redirect_to messages_url, notice: "Chat history has been cleared!" 
      rescue ActiveRecord::RecordNotDestroyed => invalid
        puts invalid.record.errors
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Message.find(params[:id])
    end
    # Placeholder for possible future functionality
    def session_id
      1
    end
    # Checks in our session to see if a logged in user exists
    def check_authenticated
      if current_user.blank?
        render plain: '401 Unauthorized', status: :unauthorized
      end
    end

    # Only allow a list of trusted parameters through.
    def message_params
      params.require(:message).permit(:content)
    end
end
