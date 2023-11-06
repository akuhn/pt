require 'pry'
require 'options_by_example'

require './quiz'


Options = OptionsByExample.new("Usage: $0 [-i, --interactive]").parse(ARGV)

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

# Engage the user with a randomized translation challenge, offering immediate
# feedback and vocal pronunciation, while recording his performance.

quiz.run num = 25

