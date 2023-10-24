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

class Result < Struct.new(:key, :pt, :en, :ask, :success, :answer, :ts)
end

results = DATABASE.execute('SELECT * FROM `quiz_v2`')
  .map { |key, pt, en, ask, success, answer, ts|
    Result.new key, pt, en, ask.to_sym, success == 1, answer, ts
  }
  .sort_by(&:ts).reverse

successes = []
probabilities = results
  .group_by { |each| [each.key, each.ask] }
  .map { |k, group|
    if group.empty?
      [k, 1]
    elsif group.first.success
      successes << [k, group.first.ts]
      [k, nil]
    else
      [k, 2 ** group.take(3).reject(&:success).count]
    end
  }
  .to_h
max_p = probabilities.values.compact.max
successes.sort_by(&:last).reverse.map(&:first).each_with_index do |k, n|
  p = max_p * ((1.0 * n / successes.length) ** 3)
  raise if probabilities[k]
  probabilities[k] = p
end


binding.pry if Options.include? :interactive


# Engage the user with a randomized translation challenge, offering immediate
# feedback and vocal pronunciation, while recording his performance.

results_index = results.group_by(&:key)
correct = 0
wrong = 0

words.entries.shuffle.each do |key, each|
  if (max_p * rand) < probabilities.fetch([key, :pt], 1.0)
    word, ask = :en, :pt
  elsif (max_p * rand) < probabilities.fetch([key, :en], 1.0)
    word, ask = :pt, :en
  else
    next
  end

  puts "Translate to #{ask.upcase}: #{each[word]}"
  answer = gets.strip

  expected = each[ask].downcase.split('/').map(&:strip)
  success = expected.include?(answer.downcase)

  if success
    puts "Correct!"
    correct += 1
  else
    previous_answers = results_index.fetch(key, [])
      .select { |r| r.success == false and r.ask == ask }
      .map(&:answer)
      .compact

    puts previous_answers if previous_answers.any?
    puts "Wrong, the correct answer is:\n#{each[ask]}"
    puts
    wrong += 1
  end

  `say -v Joana --rate 90 #{each[:pt]}`

  DATABASE.execute %{
    INSERT INTO `quiz_v2` (`reference`, `pt`, `en`, `dir`, `success`, `answer`)
    VALUES (?, ?, ?, ?, ?, ?)
  }, [key, each[:pt], each[:en], ask.to_s, success ? 1 : 0, (answer unless success)]

  print 100 * correct / (correct + wrong)
  print '%'
  puts
  puts
end

puts "Results:"
puts "Correct: #{correct}"
puts "Wrong: #{wrong}"
