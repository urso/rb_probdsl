
require 'rubygems'

require 'probdsl'
include ProbDSL

# We will now explore some  simple techniques to improve evaluation
# performance. 
#
# In the example we want define a function which returns the probability of
# flipping a coin n time the consecutive experiments will show the oposite
# side. for example we want the probability for: 
# P({H, T, H, T...}) U P({T, H, T, H...})
#

# This is a very direct solution flipping a coin n-times.
# Unfortunately due to the fact a probabilistic decision tree is
# build for large n (even for not so large n) this direct solution
# will become quite expensive. The complexity of this function
# is O(2^n).
def coins(n)
    (2..n).reduce(flip 0.5) { |acc,*|
        acc != flip(0.5)
    }
end

#
# This solution looks a little more verbose, but its complexity is much
# reduces, saveing us much much time.  In comparison to the function "coins"
# not the whole tree is build at once, but subtrees will be evaluated in
# advance using "prob {...}" which actually returns the final probability
# Distribution of the subtree. Using the function "dist" the probability
# distribution is reused in the probabilistic computation then, thus every
# subtree of height 2 is precomputed in advance.
#
def coins2(n)
    dist( (2..n).reduce(prob{flip 0.5}) { |acc,*|
        prob { dist(acc) != flip(0.5) }
    } )
end

#
# This solution is very much alike "coins2", but instead of using "prob {...}" 
# just an unevalutaed probabilistic tree object is build using "run_prob
# {...}". Using the tree's methods "flatten" and "to_d" the very same
# computational effect as in "coins2" is achieved.
#
def coins3(n)
    pre = run_prob{ flip 0.5 }.flatten
    (2..n).reduce(pre) { |acc,*|
        run_prob { flip(0.5) != acc.to_d }.flatten
    }.to_d
end

require 'benchmark'

def run_bench(n)
    puts "run benchmark with n = #{n}"
    Benchmark.bmbm do |x|
        if n < 15
            x.report('directly') do
                prob { coins n }
            end
        end

        x.report('/w prob/dist') do
            prob { coins2 n }
        end

        x.report('/w flatten/to_d') do
            prob { coins3 n }
        end

    end
    puts ''
end

run_bench(14)
run_bench(100)
run_bench(1000)

