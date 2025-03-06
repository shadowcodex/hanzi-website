require 'json'

# Specify the input and output file paths.  Adjust these to your actual file paths.
input_file = '../_data/cedict_ts.u8'
output_file = '../_data/cedict_simplified.json'

def parse_line(line)
    parsed = {}
    return {} if line.empty? || line.nil? # Return empty hash instead of 0
  
    line = line.rstrip
    # line = line.rstrip('/')
    line = line.delete_suffix('/') if line.end_with?('/')
    line = line.split('/')
    return {} if line.length <= 1 # Return empty hash instead of 0
  
    english = line[1]
    char_and_pinyin = line[0].split('[')
    return {} if char_and_pinyin.length <= 1 # Return empty hash instead of 0
  
    characters = char_and_pinyin[0].split
    return {} if characters.length != 2 # Return empty hash instead of 0
  
    traditional = characters[0]
    simplified = characters[1]
    # pinyin = char_and_pinyin[1]
    # pinyin = pinyin.delete_suffix(']') if pinyin.end_with?(']')
    # pinyin = pinyin.rstrip(']') if pinyin #Only rstrip if pinyin is not nil
  
    parsed['simplified'] = simplified
    parsed['english'] = english
    parsed
  end
  
  
  
begin
  # Open the CEDICT file, handling UTF-8 encoding.
  cedict_data = File.read(input_file, encoding: 'UTF-8')

    # Extract entries and transform into a suitable format
    simplified_entries = {}
    line_number = 0

    cedict_data.lines.each do |line|
        line_number += 1
        next if line.start_with?('#') # Skip comment lines

        begin
            parsed_data = parse_line(line)
            unless parsed_data.empty?
                simplified_entries[parsed_data['simplified']] = parsed_data['english']
        end
        rescue => e
            puts "Error processing line #{line_number}: #{line.inspect}"
            puts "Error: #{e.message}"
            puts e.backtrace
        end
    end
  

  # Write the JSON data to the output file.
  File.write(output_file, JSON.pretty_generate(simplified_entries))
  puts "JSON data written to #{output_file}"

rescue Errno::ENOENT
  puts "Error: Input file '#{input_file}' not found."
rescue EncodingError => e
  puts "Error: Encoding error encountered: #{e.message}"
  puts "Please ensure the input file is encoded in UTF-8."
rescue => e
  puts "An unexpected error occurred: #{e.message}"
  puts e.backtrace
end
