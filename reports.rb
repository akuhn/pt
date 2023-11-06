require './quiz'


class Quiz

  def print_top_ten_failures(weighting = 0.618)

    top_failures = @results.values
      # .select { |answers| answers.first.reference.end_with? ?a }
      .sort_by { |answers|
        answers.map.with_index { |each, n| each.failure ? weighting ** n : 0 }.sum
      }
      .reverse
      .take(10)

    puts "# Top Ten Areas of Improvement"
    puts

    top_failures.each do |answers|

      lang = answers.first.lang
      word = @words[answers.first.reference]

      puts "Translate to #{lang.upcase}: #{word.question(lang)}"
      puts answers.map(&:answer).compact.map(&:strip).reject(&:empty?)
      puts "Wrong, the correct answer is:\n#{word.answer(lang)}"
      puts "0%"
      puts
    end
  end
end

