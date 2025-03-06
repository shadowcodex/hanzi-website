require 'openai'
require 'dotenv/load' # For loading environment variables from .env file
require 'json'

# Load API key from .env file
OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_API_KEY')
end

def query_openai(prompt, hanzi_text)
  client = OpenAI::Client.new
  response = client.chat(
    parameters: {
      model: "gpt-4o",
      messages: [
        { role: "system", content: "You are a helpful assistant, skilled at translating Mandarin Chinese to English." },
        { role: "user", content: "#{prompt}\n\n#{hanzi_text}" }
      ],
      temperature: 0.1,
      response_format: { type: "json_object" }
    }
  )

  # Extract the content from the response
  return response.dig("choices", 0, "message", "content")
end

def process_hanzi_file(filepath)
  results = []

  # Check if file exists
  if !File.exist?(filepath)
    puts "Error: file #{filepath} does not exist!"
    return results
  end

  file_content = File.read(filepath)
  hanzi_blocks = file_content.split("\n\n\n\n") # Split by four newlines

  hanzi_blocks.each_with_index do |block, index|
    puts "Processing block #{index + 1} of #{hanzi_blocks.length}"
    hanzi_text = block.strip # Remove any leading or trailing whitespace
    prompt = "Given these lines of Mandarin Hanzi, generate the English translation line by line. Return as a JSON array and only return the JSON array, nothing else. Each item in the array should the value of the `translation` key. Do not output anything else."

    # Query OpenAI
    begin
      openai_response = query_openai(prompt, hanzi_text)
       # Attempt to parse the response as JSON
      parsed_response = JSON.parse(openai_response)

      results << { "block": index + 1, "hanzi": hanzi_text, "response": parsed_response }
    rescue JSON::ParserError => e
      puts "Error: Could not parse JSON from OpenAI response for block #{index + 1}: #{e.message}"
      puts "Raw response: #{openai_response}" # Print the raw response for debugging
      results << { "block": index + 1, "hanzi": hanzi_text, "response": "Error: Could not parse JSON - Check Raw Response"}
    rescue => e
      puts "Error: An unexpected error occurred while processing block #{index + 1}: #{e.message}"
      puts e.backtrace
      results << { "block": index + 1, "hanzi": hanzi_text, "response": "Error: #{e.message}" }
    end
  end

  return results
end

# Main execution
input_file = '../_data/hanzi_blocks.txt' # Replace with your input file
output_file = '../_data/hanzi_translation.json' # output file

results = process_hanzi_file(input_file)

# Save output file
if results.length > 0
  File.write(output_file, JSON.pretty_generate(results))
  puts "Results saved to #{output_file}"
else
  puts "No results to save."
end
