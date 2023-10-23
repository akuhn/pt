require 'pry'
require 'sqlite3'


DATABASE = SQLite3::Database.new('portugese_words_100.sqlite')
fname = 'portugese_words_100.md'

words = {}
num, letter = nil, nil

File.foreach(fname) do |line|
  if line =~ /^\d+/
    num = Integer line
    letter = 'a'
  else
    pt, en, pronunciation = line.split('=')
    if pt and en
      words["#{num}.#{letter}"] = {
        pt: pt.strip,
        en: en.strip,
      }
      letter = letter.succ
    end
  end
end

DATABASE.execute %{
  CREATE TABLE IF NOT EXISTS `quiz` (
      `reference` VARCHAR(8),
      `pt` TEXT NOT NULL,
      `en` TEXT NOT NULL,
      `dir` CHAR(2) NOT NULL,
      `success` BOOLEAN NOT NULL,
      `ts` DATETIME DEFAULT CURRENT_TIMESTAMP
  )
}

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
    INSERT INTO `quiz` (`reference`, `pt`, `en`, `dir`, `success`)
    VALUES (?, ?, ?, ?, ?)
  }, [key, each[:pt], each[:en], en.to_s, success ? 1 : 0]

  puts 100 * correct / (correct + wrong)
  puts
end

puts "Results:"
puts "Correct: #{correct}"
puts "Wrong: #{wrong}"
