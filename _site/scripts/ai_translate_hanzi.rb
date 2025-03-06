require 'openai' # gem install ruby-openai -- https://github.com/alexrudall/ruby-openai
require 'json'
require 'jieba_rb' # gem install jieba_rb
require 'erb'
require 'base64'
require 'cgi'
require 'i18n'
require 'securerandom'
require 'optparse' # Required for parsing command line arguments

I18n.config.available_locales = [:en]  # Ensure English is available
I18n.default_locale = :en

def parse_hanzi(hanzi_string, dictionary_entries, seg, tagging)
  local_dictionary = {}  # Initialize a local dictionary for the current lesson

  # 1. Split the hanzi by words
  hanzi_words = seg.cut(hanzi_string) # Use jieba to cut the hanzi into words

  # 2 & 3. Grab POS tags and lookup in dictionary
  hanzi_words.each do |word|
    # Grab the POS tags
    tags = tagging.tag(word)

    # lookup the word in dictionary
    definition = dictionary_entries[word]

    if definition
        #format the string
        definition_string = ""
        tags.each do |tag|
            definition_string += "(#{tag.values.first}) "
        end
        definition_string += " " + definition
      # 4. Store in the local dictionary
      local_dictionary[word] = definition_string
    else
        next
    end
  end

  encoded_json = ERB::Util.url_encode(Base64.strict_encode64(local_dictionary.to_json))

  return encoded_json
end

def query_openai(prompt, hanzi_text, client)
  response = client.chat(
    parameters: {
      model: "gpt-4o-mini", # 4o-mini works just fine for what we are doing and significantly cheaper.
      messages: [
        { role: "system", content: "You are a helpful data assistant, skilled at translating Mandarin Chinese to English. You pride yourself in your completness and accuracy. Translating all hanzi you see." },
        { role: "user", content: "#{prompt}\n\n#{hanzi_text}" }
      ],
      temperature: 0.1,
      response_format: { type: "json_object" }
    }
  )
  puts response

  # Extract the content from the response
  return response.dig("choices", 0, "message", "content")
end

def process_hanzi_file(filepath, client, dictionary_entries, seg, tagging)
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
    level = hanzi_text.lines[0].split(':')[1].strip
    title = hanzi_text.lines[1].split(':')[1].strip
    hanzi_text = hanzi_text.lines.drop(2).join.strip

    prompt = <<-TEXTINPUT
Given these lines of Mandarin Hanzi, generate the English translation line by line. 


Return as a JSON array and only return the JSON array, nothing else. 

Each array item will be a tuple of (original_hanzi, translation).

Do this for ALL lines of the input Hanzi.

Do not output anything else.
TEXTINPUT


    # Query OpenAI
    begin
      openai_response = query_openai(prompt, hanzi_text, client)
      #  Attempt to parse the response as JSON
      parsed_response = JSON.parse(openai_response)
      #puts parsed_response #removed

      results << {
          "block": index + 1, 
          "level": level, 
          "title": "[" + level + "] " + title,
          "slug":  CGI.escape(I18n.transliterate(level + "_" + title+"-"+SecureRandom.hex(4)).downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')),
          "hanzi": hanzi_text, 
          "translation": ERB::Util.url_encode(Base64.strict_encode64(parsed_response['translations'].to_json)),
          "dictionary": parse_hanzi(hanzi_text, dictionary_entries, seg, tagging)
        }
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

# Default file paths
DEFAULT_INPUT_FILE = '../_data/hanzi_blocks.txt'
DEFAULT_OUTPUT_FILE = '../_data/hanzi_translation.json'
DEFAULT_DICTIONARY_FILE = '../_data/cedict_simplified.json'

# Parse command-line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby ai_translate_hanzi.rb [options]"

  opts.on("-i", "--input-file [FILE]", String, "Input file path (default: #{DEFAULT_INPUT_FILE})") do |file|
    options[:input_file] = file
  end

  opts.on("-o", "--output-file [FILE]", String, "Output file path (default: #{DEFAULT_OUTPUT_FILE})") do |file|
    options[:output_file] = file
  end

    opts.on("-d", "--dictionary-file [FILE]", String, "dictionary file path (default: #{DEFAULT_DICTIONARY_FILE})") do |file|
        options[:dictionary_file] = file
    end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

# Set file paths based on options or defaults
input_file = options[:input_file] || DEFAULT_INPUT_FILE
output_file = options[:output_file] || DEFAULT_OUTPUT_FILE
dictionary_file = options[:dictionary_file] || DEFAULT_DICTIONARY_FILE

puts "input file: #{input_file}"
puts "output file: #{output_file}"
puts "dictionary file: #{dictionary_file}"

dictionary_entries = JSON.parse(File.read(dictionary_file))

# Load API key from .env file
openai_client = OpenAI::Client.new(
  access_token:  ENV['OPENAI_API_KEY'],
  log_errors: true # Highly recommended in development, so you can see what errors OpenAI is returning. Not recommended in production because it could leak private data to your logs.
)

# Initialize Jieba for word segmentation and POS tagging
seg = JiebaRb::Segment.new  # equivalent to "JiebaRb::Segment.new mode: :mix"
tagging = JiebaRb::Tagging.new

# Process file
results = process_hanzi_file(input_file, openai_client, dictionary_entries, seg, tagging)

# Save output file
if results.length > 0
  File.write(output_file, JSON.pretty_generate(results))
  puts "Results saved to #{output_file}"
else
  puts "No results to save."
end
