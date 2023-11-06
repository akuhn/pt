require 'sqlite3'


# Serves as the central hub for the language learning script: handling tasks
# such as connecting to the database and reading vocabulary files, as well as
# tracking how well the user is doing and adjusting the difficulty level based
# on the user's learning progress, all to make the language learning process
# smooth and user-friendly.

class Quiz

  attr_reader :correct
  attr_reader :wrong

  attr_reader :probabilities
  attr_reader :results
  attr_reader :words


  # Set up the initial environment for the quiz, establishing a database connection
  # and preparing the necessary data structures for for result tracking.

  def initialize(database)

    @db = SQLite3::Database.new(database)
    @words = Hash.new
    @correct = 0
    @wrong = 0

    @db.execute %{
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
  end


  # Read a file containing word pairs, parse and instantiate them into Word
  # objects with unique identifiers for quick access during the quiz.

  def load_words_from_file(fname)
    num, letter = nil, nil

    File.foreach(fname) do |line|
      if line =~ /^\d+/
        num = (Integer line)
        letter = 'a'
      else
        pt, en, *ignore = line.split('=')
        if pt and en
          word = Word.new("#{num}.#{letter}", pt.strip, en.strip)
          @words[word.reference] = word
          letter = letter.succ
        end
      end
    end
  end


  # Retrieve historical quiz answers data from the database, constructing
  # Result objects that provide insight into language learning patterns
  # and facilitate the identification of learning trends.

  def load_results_from_database
    @results = @db.execute('SELECT * FROM `quiz_v2`')
      .map { |reference, pt, en, lang, success, answer, ts|
        Result.new reference, pt, en, lang.to_sym, success == 1, answer, ts
      }
      .sort_by(&:ts).reverse
      .group_by { |each| [each.reference, each.lang] }
  end

  # Analyze past answers to assign adaptive learning probabilities to each
  # word, ensuring a personalized and efficient learning path by focusing
  # on frequent stumbling blocks and reinforcing past successes.

  def assign_adaptive_learning_probabilities
    partitions = @results.group_by do |_, answers|
      case answers.take_while(&:success).length
      when 0
        :fail
      when 1
        :success
      else
        :streak
      end
    end

    streaks_weighted_by_age =  calculate_normalize_squared_index(
      partitions[:streak].sort_by { |combo, rx| rx.first.ts }.reverse
    )

    successes_weighted_by_recency = calculate_normalize_squared_index(
      partitions[:success].sort_by { |combo, rx| rx.first.ts }
    )

    failures_weighted_by_count_and_age =  calculate_normalize_squared_index(
      partitions[:fail].sort_by { |combo, rx|
        [rx.take(3).reject(&:success).count, rx.first.ts]
      }.reverse
    )

    @probabilities = Hash.new.merge(
      streaks_weighted_by_age,
      successes_weighted_by_recency,
      failures_weighted_by_count_and_age,
    )
  end

  # Execute the quiz session, dynamically selecting questions based on adaptive
  # probabilities, providing real-time feedback and limiting to 25 questions to
  # maintain user engagement and focus.

  def run(num = 25)
    @correct = 0
    @wrong = 0

    @words.values.shuffle.each do |each|
      if rand < @probabilities.fetch([each.reference, :pt], 0.5)
        lang = :pt
      elsif rand < @probabilities.fetch([each.reference, :en], 0.5)
        lang = :en
      else
        next
      end

      ask_question each.reference, lang

      break if (@correct + @wrong) == 25
    end

    puts "Results:"
    puts "Correct: #{@correct}"
    puts "Wrong: #{@wrong}"
  end

  # Pose a targeted translation question to the user, evaluate the response for
  # accuracy, offer corrective feedback with prior incorrect attempts and use
  # speech-synthesis to reinforce learning through auditory exposure, all while
  # tracking the performance to further personalize future learning sessions.

  def ask_question(reference, lang)
    word = @words[reference]

    puts "Translate to #{lang.upcase}: #{word.question(lang)}"
    answer = gets.strip

    expected = word.answer(lang).downcase.split('/').map(&:strip)
    success = (expected.include? answer.downcase)

    if success
      puts "Correct!"
      @correct += 1
    else
      previous_answers = @results.fetch([reference, lang], [])
        .reject(&:success)
        .map(&:answer)
        .compact

      puts previous_answers if previous_answers.any?
      puts "Wrong, the correct answer is:\n#{word.answer(lang)}"
      @wrong += 1
    end

    `say -v Joana --rate 90 #{word.pt}`

    @db.execute %{
      INSERT INTO `quiz_v2` (`reference`, `pt`, `en`, `dir`, `success`, `answer`)
      VALUES (?, ?, ?, ?, ?, ?)
    }, [reference, word.pt, word.en, lang.to_s, success ? 1 : 0, (answer unless success)]

    print 100 * @correct / (@correct + @wrong)
    print '%'
    puts
    puts
  end

  private

  # Calculate weighted probabilities for quiz questions based on their position
  # in an array, enabling a frequency-based selection that adapts to the user's
  # learning progress.

  def calculate_normalize_squared_index(array)
    probabilities = {}
    array
      .map(&:first)
      .each_with_index { |combo, n|
        probabilities[combo] = (1.0 * n / array.length) ** 2
      }

    return probabilities
  end
end


# Represents a bilingual vocabulary unit with reference identifiers, offering
# methods to get the appropriate question and answer depending on the language
# direction, serving as a fundamental building block for quiz content.

class Word < Struct.new(:reference, :pt, :en)

  def question(lang)
    lang == :pt ? en : pt
  end

  def answer(lang)
    lang == :pt ? pt : en
  end
end


# Keeps track of previous quiz performance, recording linguistic pairings,
# outcome success and timestamps, which are crucial for monitoring progress
# and adjusting future question probabilities.

class Result < Struct.new(:reference, :pt, :en, :lang, :success, :answer, :ts)
end


# And, that's it, good luck!

