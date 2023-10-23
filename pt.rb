require 'pry'
require 'sqlite3'
require 'options_by_example'


Options = OptionsByExample.new("Usage: $0 [-i, --interactive]").parse(ARGV)

DATABASE = SQLite3::Database.new('portugese_words_100.sqlite')
fname = 'portugese_words_100.md'

# Read the vocabulary file to extract word pairs, organizing them with unique
# references for easy retrieval in the performance database.

words = {}
num, letter = nil, nil

File.foreach(fname) do |line|
  if line =~ /^\d+/
    num = Integer line
    letter = 'a'
  else
    pt, en, *ignore = line.split('=')
    if pt and en
      words["#{num}.#{letter}"] = {
        pt: pt.strip,
        en: en.strip,
      }
      letter = letter.succ
    end
  end
end

# Keep a database with quiz results for tracking progress over time, enabling
# adaptive learning experiences that optimize repetitions and focus on areas of
# improvement, enabling more effective and personalized learning journeys.

DATABASE.execute %{
  CREATE TABLE IF NOT EXISTS `quiz_v2` (
      `reference` VARCHAR(8),
      `pt` TEXT NOT NULL,
      `en` TEXT NOT NULL,
      `dir` CHAR(2) NOT NULL,
      `success` BOOLEAN NOT NULL,
      `answer` TEXT,
      `ts` DATETIME DEFAULT CURRENT_TIMESTAMP
  )
}

def breakdown_by_words(en = false)
  $data ||= (DATABASE.execute 'select * from quiz_v2').group_by(&:first)
  $data
    .select { |k,vx| k =~ /a$/ }
    .map { |k,vx| [vx[0][1], (vx[0][2] if en), 1.0 * vx.sum { |ea| ea[4] } /  vx.length].compact }
    .sort_by(&:last)
end

binding.pry if Options.include? :interactive

# Engage the user with a randomized translation challenge, offering immediate
# feedback and vocal pronunciation, while recording his performance.

correct = 0
wrong = 0

words.entries.shuffle.each do |key, each|
  pt, en = [:pt, :en].shuffle
  puts "Translate to #{en.upcase}: #{each[pt]}"
  answer = gets.strip

  expected = each[en].downcase.split('/').map(&:strip)
  success = expected.include? answer.downcase

  if success
    puts "Correct!"
    correct += 1
  else
    puts "Wrong, the correct answer is\n#{each[en]}"
    wrong += 1
  end

  `say -v Joana --rate 90 #{each[:pt]}`

  DATABASE.execute %{
    INSERT INTO `quiz_v2` (`reference`, `pt`, `en`, `dir`, `success`, `answer`)
    VALUES (?, ?, ?, ?, ?, ?)
  }, [key, each[:pt], each[:en], en.to_s, success ? 1 : 0, (answer unless success)]

  print 100 * correct / (correct + wrong)
  print '%'
  puts
  puts
end

puts "Results:"
puts "Correct: #{correct}"
puts "Wrong: #{wrong}"
