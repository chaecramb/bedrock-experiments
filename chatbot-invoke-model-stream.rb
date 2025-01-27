require "aws-sdk-bedrockruntime"

SYSTEM_PROMPT = <<~PROMPT
  You are a helpful, friendly, and knowledgeable AI assistant.
  Provide concise responses and maintain a natural conversation flow.
PROMPT

class ChatBot
  MODEL_ID = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0"

  def initialize(region: "eu-west-1")
    @client = Aws::BedrockRuntime::Client.new(region: region)
  end

  def send_message_stream(messages)
    native_request = {
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: 1000,
      system: SYSTEM_PROMPT,
      messages: messages.map do |msg|
        {
          role: msg[:role],
          content: [
            { type: "text", text: msg[:content] }
          ]
        }
      end
    }

    full_response = ""

    begin
      @client.invoke_model_with_response_stream(
        model_id: MODEL_ID,
        body: JSON.generate(native_request)
      ) do |stream|
        stream.on_chunk_event do |event|
          chunk_data = JSON.parse(event.bytes)

          if chunk_data["type"] == "content_block_delta"
            delta = chunk_data["delta"]
            response_text = delta["text"]
            print response_text
            full_response << response_text
          end
        end

        stream.on_error_event do |event|
          puts "\nERROR: Stream error occurred."
          puts "Event type: #{event.event_type}"
          puts "Error code: #{event.error_code}" if event.respond_to?(:error_code)
          puts "Error message: #{event.error_message}" if event.respond_to?(:error_message)
          exit(1)
        end
      end
    rescue Aws::Errors::ServiceError => e
      puts "\nERROR: Can't invoke '#{MODEL_ID}'. Reason: #{e}"
      exit(1)
    end

    full_response
  end
end

def main
  chatbot = ChatBot.new
  messages = []

  puts "Claude 3.5 Chat - Type 'exit', 'quit', or 'bye' to end the conversation\n\n"

  loop do
    print "You: "
    input = gets&.chomp&.strip
    break if !input || input.empty?

    exit_commands = ['exit', 'quit', 'bye']
    break if exit_commands.include?(input.downcase)

    messages << { role: 'user', content: input }

    print "\nClaude: "

    response_text = chatbot.send_message_stream(messages)
    puts "\n\n"

    messages << { role: 'assistant', content: response_text }
  end

  puts "\nGoodbye! Have a great day!"
end

main if __FILE__ == $0
