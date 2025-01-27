require "aws-sdk-bedrock"

client = Aws::Bedrock::Client.new

puts client.list_foundation_models
