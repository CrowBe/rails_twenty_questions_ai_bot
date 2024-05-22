class MessagesController < ApplicationController
  before_action :set_message, only: %i[ show edit update destroy ]

  # GET /messages or /messages.json
  def index
    @messages = Message.where(session_id: session_id).order(created_at: :desc)
  end

  # GET /messages/1 or /messages/1.json
  def show
  end

  # GET /messages/new
  def new
    @message = Message.new
  end

  # GET /messages/1/edit
  def edit
  end

  # TODO: Consider setting up two separate functions that initialize our chat, including system prompt. And another one that continues on an existing chat that's passed in
  # POST /messages or /messages.json
  def create
    # Create a database record of the newest message
    @message = Message.new(message_params)
    @message.role = "user"
    @message.session_id = session_id
    
    if @message.save
      # Create our chat service and set up the system prompt
      @messages = Message.where(session_id: @message.session_id).order(created_at: :desc)
      redirect_to messages_url(@messages), notice: "Message was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # We hit this function after the user has created a new message to fetch and save the ai response
  def create_reply
    # Open up the service session and pass in the system promps
    chat_session = ChatService.new(initial_prompt: "Let's play 20 questions. Guess the word I am thinking of. Only ask yes or no questions. When you guess the correct word, respond with a celebratory statement.")
    chat_history = [chat_session.system_prompt]
    
    # Get all messages that exist in the db from the current session, loop through and insert them into our chat history variable
    Message.where(session_id: session_id).order(created_at: :asc).each do |msg|
      chat_history << {
        role: msg.role,
        content: msg.content
      }
    end
    
    # Call the chat service and pass in the chat history then add the response to the database record
    response = chat_session.call(chat_history:)
    @message = Message.new(role: "assistant", session_id: session_id, content: response)
    if @message.save
      # Add the most recent message to the list and re render the updated list of messages
      @messages = Message.where(session_id: session_id).order(created_at: :desc)
      redirect_to messages_url(@messages), notice: "Message was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /messages/1 or /messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_params)
        format.html { redirect_to message_url(@message), notice: "Message was successfully updated." }
        format.json { render :show, status: :ok, location: @message }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1 or /messages/1.json
  def destroy
    @message.destroy!

    respond_to do |format|
      format.html { redirect_to messages_url, notice: "Message was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Message.find(params[:id])
    end
    def session_id
      1
    end
    # Only allow a list of trusted parameters through.
    def message_params
      params.require(:message).permit(:content)
    end
end
