require "aws-sdk-bedrockruntime"

client = Aws::BedrockRuntime::Client.new(region: "eu-west-1")

model_id = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0"

prompt = "Describe the purpose of a 'hello world' program in one line."

native_request = {
  anthropic_version: "bedrock-2023-05-31",
  max_tokens: 1000,
  messages: [
    {
      role: "user",
      content: [
        {
          type: "text",
          text: prompt
        }
      ]
    }
  ]
}

begin
  client.invoke_model_with_response_stream(
    model_id: model_id,
    body: JSON.generate(native_request)
  ) do |stream|
    stream.on_chunk_event do |event|
      chunk_data = JSON.parse(event.bytes)

      if chunk_data["type"] == "content_block_delta"
        delta = chunk_data["delta"]
        response_text = delta["text"]
        print response_text
      end
    end

    stream.on_error_event do |event|
      puts "ERROR: Stream error occurred."
      puts "Event type: #{event.event_type}"
      puts "Error code: #{event.error_code}" if event.respond_to?(:error_code)
      puts "Error message: #{event.error_message}" if event.respond_to?(:error_message)
      exit(1)
    end
  end
rescue Aws::Errors::ServiceError => e
  puts "ERROR: Can't invoke '#{model_id}'. Reason: #{e}"
  exit(1)
end

puts
