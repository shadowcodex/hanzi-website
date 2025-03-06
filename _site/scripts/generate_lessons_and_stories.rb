require 'json'
require 'yaml'

# Load JSON file
lessons = JSON.parse(File.read('../_data/lessons.json'))

# Directory for generated pages
Dir.mkdir('../_lessons') unless Dir.exist?('../_lessons')

# Generate markdown files
lessons.each do |lesson|
  filename = "../_lessons/#{lesson['slug']}.md"

  File.open(filename, 'w') do |file|
    # file.puts "---"
    file.puts YAML.dump(lesson, allow_unicode: true)
    file.puts "layout: lessons"
    file.puts "---"
    
  end
end

puts "✅ Lesson pages generated!"

# Load JSON file
stories = JSON.parse(File.read('../_data/readings.json'))

# Directory for generated pages
Dir.mkdir('../_readings') unless Dir.exist?('../_readings')

# Generate markdown files
stories.each do |story|
  filename = "../_readings/#{story['slug']}.md"

  File.open(filename, 'w') do |file|
    # file.puts "---"
    file.puts YAML.dump(story, allow_unicode: true)
    file.puts "layout: reading"
    file.puts "---"
    
  end
end

puts "✅ Reading pages generated!"

