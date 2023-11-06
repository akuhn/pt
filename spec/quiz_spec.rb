require 'quiz'

RSpec.describe Quiz do

  it 'should load the example file' do
    quiz = Quiz.new(':memory:')
    quiz.load_words_from_file 'portugese_words_100.md'

    (expect quiz.words['1.a'].pt).to eq 'Coisa'
    (expect quiz.words['1.a'].en).to eq 'Thing'

    (expect quiz.words['69.b'].pt).to eq 'So quero um cafe.'
    (expect quiz.words['69.b'].en).to eq 'I just want a coffee.'
  end
end
