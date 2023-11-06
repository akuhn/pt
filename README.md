# Portuguese Language Quiz

Olá amigos, I've recently started learning European Portuguese and along the way crafted this little script, it’s a simple language quiz and I’m sharing it with the hope that others might find it useful too.

It quizzes you on 100 common words and phrases.

I've taken them from this video, https://youtu.be/kum5d6I8KR4

### Getting Started

Ensure you have Ruby installed on your Mac, then clone the repository and you’re good to go,

    git clone https://github.com/akuhn/pt
    cd pt
    bundle install
    bundle exec ruby pt.rb

NB, make sure to install the "Joana" voice in the system preferences.

### Features

- Command line interface for focused study sessions
- Speech synthesis for authentic European Portuguese pronunciation (go eff yourself Google translate!)
- Adaptive learning algorithm based on personal performance

The adaptive learning algorithm is crafted to personalize the study experience by tracking your performance, it prioritizes words that need extra practice and while also periodically reviewing those already mastered to reinforce retention. This approach ensures a comprehensive and effective learning process.

Here is the relevant code snippet:

    @probabilities = Hash.new.merge(
      (boost_ancient_entries partitions[:streak]),
      (boost_recent_and_ancient_entries partitions[:success]),
      (boost_recent_and_ancient_entries partitions[:failure]),
      (boost_ancient_entries partitions[:failure_streak]),
    )

To see the full mechanics of how it works, please feel free to check out the source code.


Enjoy the journey and happy learning!
