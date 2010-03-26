#!/usr/bin/env ruby

require 'rubygems'

require 'probdsl'
include ProbDSL

# Bayesian Spam filter example. 
# We try to find the probability of a message it's classification being spam
# or ham using a naive bayesian filter and a second filter using fisher's
# methods to analyse the plausibility of the first filter its result.
#
# In essence the bayesian filter tries to find the probability for the message
# being spam using the message its features and previously seen messages.
#
# Suppose we have the random variables:
# S = {:Spam, :Ham}
# Document = Set of words/features = {Wi ... Wn}
# Wi = word Wi present or not present {true, false}
#
# then
#
# P(S|Document) = P(S|W1) * P(S|W2) * ... * P(S|Wn)
# 
# meaning we assume all feature/words to be statistically independent (hence
# naive bayesian filter).
#
# Finding words in old message and their spam/ham count we can drive the
# filter.
#
# Next let's find the probability for spam given a word P(S|Wi):
#
#            P(Wi|S) * P(S)
# P(S|Wi) = ---------------
#                P(Wi)
#
# But to minimize computational effort a classifier for each word assuming a
# uniform prior distribution P(S) is precomputed and the true prior is used
# later on inference. So we can store the classifiers directly in our database
# instead of recomputing them over and over again.
#
# P(S|Document) = < P(S|W1) * P(S|W2) * ... >
#            = < P(W1|S) * prior * P(W2|S) * prior * ... >
#
# here < P(...) > stands for "alpha * P(...)" and expresses normalization which
# is done automatically by our library. Thus
#
#             P(Wi|S) * P(S)
#  P(S|Wi) = ---------------- = < P(Wi|S) * P(S) >
#                 P(Wi)
#
# First we need to explain how the classifiers are precomputed and how these
# precomputed classifiers are used to do the classification:
# 
# Suppose P_uni is uniform distribution for spam/ham, thus P_uni(spam) = 0.5
# and P_uni(ham) = 0.5. Then
# 
#                  P(Wi | S) * P_uni(S)             P(Wi | S) * P_uni(S)
#  P_uni(S | Wi) = --------------------  =  ------------------------------------
#                       P(Wi)               Sum(s={spam,ham}) P(Wi|s) * P_uni(s)
# 
#                = < P(Wi|S) * P_uni(S) >
# 
# now Suppose the real prior is given, thus with new prior:
#
# P_prior(S|Wi) = < P(Wi|S) * P_prior(S) >
# 
#                 P(Wi|S) * P_prior(S)     P_uni(S|Wi) * P_prior(S)
#               = --------------------  =  ------------------------
#                       P(Wi)                      P_uni(S)
# 
#               = < P_uni(S|Wi) * P_prior(S) >
#
#               = P(S|Wi)
# 
# P(S|Document) = < P(S|W1) * P(S|W2) * ... >
#               = < P(W1|S) * P_prior(S) * P(W2|S) * P_prior(S) * ... >
#               = < P_uni(S|W1) * P_prior(S) * P_uni(S|W2) * P_prior(S)  * ... >
#
# Using these, our classifiers to store in the database are P_uni(S|Wi) for
# each word found during learning. So when learning from new message not all
# classifiers need to be recomputed. Alternatively one may want to store
# P_prior(S|Wi) in the database, but when learning from new messages all
# classifiers need to be updated then. One may even assume the prior to always
# be distributed uniform. In that case P(S|Document) becomes
# P(S|Document) = < P_uni(S|W1) * P_uni(S|W2) ... >
#
# Instead of using all classifiers for all words found only a subset is used.
# This subset of classifiers to use is found by scoring the classifiers and
# using the classifiers with highest scores for the words found in the
# document.
#
# Scoring is done by computing the 'quadratic distance' of a classifier to the
# uniform distribution:
# score = ( 0.5 - P_uni(S=spam|Wi) )^2 + ( 0.5 - P_uni(S=ham|Wi))^2
#
# Furthermore if a classifier assumes P_uni(S=spam|Wi) = 0 or P_uni(S=ham|Wi) = 0
# the probability will be adjusted to 0.01.
#    

S = [:Spam, :Ham]

# module to be mixed into a 'Spam Feature Database' to compute probabilities
# from the database.
#
# It's assumed that the 'Spam Feature Database' provides the following
# functions:
#
# countWord(word:String, type:{:Spam, :Ham}) => Int # occurences of word given 
#                                                   # Spam/Ham messages
#
# countType(type:{:Spam, :Ham}) => Int # number of Spam/Ham messages learned
#
module SpamDatabaseProbabilities
    # probabilities
    #
    # S = {:Spam, :Ham} ; Set of possible message type
    # P(S) <- prior probability
    #
    # W = {set of known words}
    # P(W|S) <- likelyhood
    
    def pMsgType # P(S)
        prob do
            dist @msgCounts.zip(types)
        end
    end

    def pWord(word, type) # P(W == word | S == type)
        n = countWord(word, type).to_f
        total = countType(type).to_f
        flip  n / total, true, false
    end

    # P(S | W == word) = < P(W == word | S) * prior >
    def pHasWord(word, clazz)    
        guard( pWord(word, clazz) )
        clazz
    end
end

# our test database
class SpamBaseKnowledge
    include SpamDatabaseProbabilities

    def initialize
        @msgCounts = [103, 57]
        @wordCountTable = block1({
            "the" => [1, 2],
            "quick" => [1, 1],
            "brown" => [0, 1],
            "fox" => [0, 1],
            "jumps" => [0, 1],
            "over" => [0, 1],
            "lazy" => [0, 1],
            "dog" => [0, 1],
            "make" => [1, 0],
            "money" => [1, 0],
            "in" => [1,0],
            "online" => [1,0],
            "casino" => [1, 0],
            "free" =>  [57, 6],
            "bayes" => [1, 10],
            "monad" => [0, 22],
            "hello" => [30, 32],
            "asdf"  => [40, 2]
        }) { |h| h.default = [0,0] }
    end

    def types
        S
    end

    def knownWords
        @wordCountTable.keys
    end

    def countType(type)
        if type != :Spam && type != :Ham
            return 0
        else
            @msgCounts[ type2Index type ]
        end
    end

    def countWord(word, type)
        @wordCountTable[word][ type2Index type ]
    end

    private
    def type2Index(type)
        if type == :Spam then 0 else 1 end
    end
end

# The naive bayesian classifier.
BayesianStrategy = proc {|classifiers, prior, _, _|
    classifiers.map { |c|
        # compute < P_uni(S|Wi) * P_prior(S) > 
        # and use nil for invalid cases to do doing bayesian inference  (it is
        # important to use nil for invalid cases until the end for invalid
        # cases for normalization).
        prior.dep { |t|
            c.map { |t_c| t == t_c ? t : nil }
        }
    }.inject { |da, db| # multiply all probabilities (naive bayesian part)
        da.dep { |t|
            db.map { |t_b| t == t_b ? t : nil }
        }
    }.normalize
}

# use bayesian classifier and analyse using fisher's method
FisherStrategy = proc {|classifiers, prior, n, words|
    hypothesis = BayesianStrategy.call(classifiers, prior, n, words)
    dof = classifiers.length # dof / 2
    map = Hash.new(0)

    for p,k in hypothesis
        # chi_square = -2.0 * sum(i) { log(p_i) } 
        #            = -2.0 * log(p)
        #
        # copmute p-value by solving
        #
        # integral( x^(n-1) * exp(-x/2) / (gamma(n) * 2^n) , -2 log(p), inf, dx)
        #
        #   integral ( x^(n-1) * exp(-x/2), -2 log(p), inf, dx) 
        # = ---------------------------------------------------
        #                       gamma(n) * 2^n
        #
        # = p * Sum(i = 1 to n) { (-log(p))^(n - i) / (n - i)! }
        #
        # = p + p * Sum(i = 1 to n-1) { (-log(p))^(n - i) / (n - i)! }
        #
        # with n = dof

        m = -Math.log(p) # 0.5 chi
        t = p # exp(-m) = exp(log(p)) = p

        # compute p value
        tmp = 1.upto(dof-1).reduce(t) {|sum,i|
            t *= m / i.to_f
            sum + t
        }

        map[k] = if tmp < 1.0 then tmp else 1.0 end
    end
    map
}

# other part of the database computing, scoring and storing the classifiers 
# P_uni(S|Wi)
class SpamClassifier

    def initialize(knowledge, strategie)
        @knowledge = knowledge # our database
        @classifiers = {}      # the classifiers
        @strategie = strategie # the strategy to use, naive bayesian or fisher's method

        buildClassifiers {|w,s,probs|
            @classifiers[w] = [s,probs]
        }
    end

    def pMsgTypeByWords(words, n = 15, prior = @knowledge.pMsgType)
        @strategie.call(findClassifiers(words, n), prior, n, words)
    end

    # classify a message using the n most prominent classifiers
    def classify(words, n = 15)
        pMsgTypeByWords(words, n).most_probable
    end

    private
    def characteristic(f)
        norm_prob do
            f.call uniform(@knowledge.types)
        end
    end

    def score(&blk)
        characteristic(blk).distance prob{ uniform(@knowledge.types) }
    end

    def buildClassifiers
        @knowledge.knownWords.each {|w,types|
            s = score do |prior| 
                @knowledge.pHasWord(w,prior)
            end
            probs = norm_prob do
                @knowledge.pHasWord(w, uniform(@knowledge.types))
            end
            yield w, s, probs.adjust_min
        }
    end

    def findClassifiers(words, n)
        classifiers = words.map {|w| [w, @classifiers[w]] }.delete_if {|w,c| c == nil}
        classifiers.sort! {|x,y| x[1][0] <=> y[1][0]}
        classifiers[0,n].map {|w,(s,prob)| 
            prob 
        }
    end
end

# run some tests using the test database, some key words and the different
# strategies
classifiers = [ ["bayesian", SpamClassifier.new(SpamBaseKnowledge.new, BayesianStrategy)], 
                ["fisher's method", SpamClassifier.new(SpamBaseKnowledge.new, FisherStrategy)] ]

testCorpus = [["free"],
              ["monad"],
              ["free", "asdf", "bayes", "quick", "jump", "test"],
              ["free", "monad", "asdf", "bayes", "quick", "jump", "test"]
             ]

puts "\ntest classifier"
testCorpus.each do |data|
    printf "use corpus: #{data}\n"
    classifiers.each do |n, c|
        puts n
        puts c.pMsgTypeByWords(data)
        puts ""
    end
end

