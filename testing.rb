require "rspec"
require "aws-sdk-bedrockruntime"
# tried adding webmock but it's nightmare/impossible to use with AWS
require "webmock/rspec"

def bedrock_request
  client = Aws::BedrockRuntime::Client.new(region: "eu-west-1")

  response = client.converse(
    model_id: "eu.anthropic.claude-3-5-sonnet-20240620-v1:0",
    messages: [
      {
        role: "user",
        content: [{text: "say 'hello world'"}]
      }
    ],
    inference_config: {
      max_tokens: 1000,
      temperature: 1.0,
    },
  )

  response["output"]["message"]["content"][0]["text"]
end

def stub_bedrock_request(...)
  # use an ivar so we keep existing stubs - not sure if this is much use if
  # we only use one endpoint (as stubs are reset on each call) but seems
  # necessary if we use more than one endpoint and I assume we'll eventually
  # want one for embedding
  @bedrock_client ||= Aws::BedrockRuntime::Client.new(stub_responses: true)
  allow(Aws::BedrockRuntime::Client).to receive(:new).and_return(@bedrock_client)
  @bedrock_client.stub_responses(...)
end

RSpec.describe "BedrockChatbot" do
  it "does something" do
    # anytime we stub an endpoint it resets any existing stubs, so we'll have
    # to do them in sequence as an array
    stub_bedrock_request(:converse, [
      {
        output: {
          message: {
            role: "assistant",
            content: [
              { text: "hello from first request" }
            ]
          },
        },
        stop_reason: 'end_turn',
        usage: {
          input_tokens: 10,
          output_tokens: 20,
          total_tokens: 30
        },
        metrics: {
          latency_ms: 999
        }
      },
      # we can use a lambda as a way to have a dynamic response, which seems
      # most useful for us to match input was expected
      -> (context) { 
        next "NotFound" unless context.params.dig(:messages, 0, :content, 0, :text) == "say 'hello world'"
        
        {
          output: {
            message: {
              role: "assistant",
              content: [
                { text: "Hello from stub" }
              ]
            },
          },
          stop_reason: 'end_turn',
          usage: {
            input_tokens: 10,
            output_tokens: 20,
            total_tokens: 30
          },
          metrics: {
            latency_ms: 999
          }
        }
      }
    ])

    expect(bedrock_request).to eq("hello from first request")
    expect(bedrock_request).to eq("Hello from stub")
  end
end
