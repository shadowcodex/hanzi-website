require 'jieba_rb'
require 'json'
require 'erb'

dictionary_file = '../_data/cedict_simplified.json'
lesson_file = '../_data/lessons_input.json'

# Load the dictionary and lesson entries
dictionary_entries = JSON.parse(File.read(dictionary_file))
lesson_entries = JSON.parse(File.read(lesson_file))

# Initialize the overall output dictionary
lessons_with_local_dictionaries = {}

# Initialize Jieba for word segmentation and POS tagging
seg = JiebaRb::Segment.new  # equivalent to "JiebaRb::Segment.new mode: :mix"
tagging = JiebaRb::Tagging.new

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

  encoded_json = ERB::Util.url_encode(local_dictionary.to_json)

  return encoded_json
end


# Iterate through each lesson
lesson_entries.each do |lesson|
  lesson_slug = lesson['slug']
  lesson['dictionary'] = parse_hanzi(lesson['hanzi'], dictionary_entries, seg, tagging)
  
end

# Optionally, output the results to a JSON file
output_file = '../_data/lessons_local_dictionaries.json'
File.write(output_file, JSON.pretty_generate(lesson_entries))

puts "Local dictionaries generated and saved to #{output_file}"
