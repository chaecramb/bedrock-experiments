require "aws-sdk-bedrockruntime"

client = Aws::BedrockRuntime::Client.new(region: "eu-west-1")

model_id = "eu.anthropic.claude-3-5-sonnet-20240620-v1:0"

tweet = "I'm a HUGE hater of pickles.  I actually despise pickles.  They are garbage."

query = <<QUERY
<text>
#{tweet}
</text>

Only use the print_sentiment_scores tool.
QUERY

tools = [
    {
        name: "print_sentiment_scores",
        description: "Prints the sentiment scores of a given text.",
        input_schema: {
            type: "object",
            properties: {
                positive_score: {"type": "number", "description": "The positive sentiment score, ranging from 0.0 to 1.0."},
                negative_score: {"type": "number", "description": "The negative sentiment score, ranging from 0.0 to 1.0."},
                neutral_score: {"type": "number", "description": "The neutral sentiment score, ranging from 0.0 to 1.0."}
            },
            required: ["positive_score", "negative_score", "neutral_score"]
        }
    }
]

native_request = {
  anthropic_version: "bedrock-2023-05-31",
  max_tokens: 1000,
  tools: tools,
  messages: [
    {
      role: "user",
      content: query
    }
  ]
}

begin
  response = client.invoke_model(
    model_id: model_id,
    body: JSON.generate(native_request)
  )
rescue Aws::Errors::ServiceError => e
  puts "ERROR: Can't invoke '#{model_id}'. Reason: #{e}"
  exit(1)
end

model_response = JSON.parse(response.body.read)
tool_response = model_response["content"].find { |content| content["type"] == "tool_use" }
json_sentiment = tool_response["input"]

puts "Sentiment Analysis (JSON):"
puts JSON.pretty_generate(json_sentiment)
