require 'pry'
require 'options_by_example'

require './quiz'


Options = OptionsByExample.new("Usage: $0 [-i, --interactive] [--top10]").parse(ARGV)

# Read the vocabulary file to extract word pairs, organizing them with unique
# references for easy retrieval in the performance database.

quiz = Quiz.new('portugese_words_100.sqlite')
quiz.load_words_from_file 'portugese_words_100.md'


# Keep a database with quiz results for tracking progress over time, enabling
# adaptive learning experiences that optimize repetitions and focus on areas of
# improvement, enabling more effective and personalized learning journeys.

quiz.load_results_from_database
@probabilities = quiz.assign_adaptive_learning_probabilities

binding.pry if Options.include? :interactive

if Options.include? :top10

  top_failures = quiz.results.values
    # .select { |answers| answers.first.reference.end_with? ?a }
    .sort_by { |answers|
      answers.map.with_index { |each, n| each.failure ? 0.618 ** n : 0 }.sum
    }
    .reverse
    .take(10)

  puts "# Top Ten Areas of Improvement"
  puts

  top_failures.each do |answers|

    lang = answers.first.lang
    word = quiz.words[answers.first.reference]

    puts "Translate to #{lang.upcase}: #{word.question(lang)}"
    puts answers.map(&:answer).compact.map(&:strip).reject(&:empty?)
    puts "Wrong, the correct answer is:\n#{word.answer(lang)}"
    puts "0%"
    puts
  end

  exit
end


# Engage the user with a randomized translation challenge, offering immediate
# feedback and vocal pronunciation, while recording his performance.

quiz.run num = 25

