require 'quiz'

RSpec.describe Quiz do

  it 'should load the example file' do
    quiz = Quiz.new(':memory:')
    quiz.load_words_from_file 'portugese_words_100.txt'

    (expect quiz.words['1.a'].pt).to eq 'Coisa'
    (expect quiz.words['1.a'].en).to eq 'Thing'

    (expect quiz.words['69.b'].pt).to eq 'So quero um cafe.'
    (expect quiz.words['69.b'].en).to eq 'I just want a coffee.'
  end

  it 'should quiz the user' do
    quiz = Quiz.new(':memory:')
    quiz.load_words_from_file 'portugese_words_100.txt'
    quiz.load_results_from_database
    quiz.assign_adaptive_learning_probabilities

    expect(quiz).to receive(:`).and_return(nil)
    expect(quiz).to receive(:gets).and_return('coisa')
    expect {
      quiz.ask_question('1.a', :pt)
    }.to output(/correct!/i).to_stdout

    expect(quiz).to receive(:`).and_return(nil)
    expect(quiz).to receive(:gets).and_return('fulano de tal')
    expect {
      quiz.ask_question('69.b', :pt)
    }.to output(/wrong, the correct answer is/i).to_stdout
  end
end
