
require 'rubygems'
require 'probdsl'
include ProbDSL

#
# found here: http://heath.hrsoftworks.net/archives/000036.html
#

def die
    uniform 1..6
end

puts <<HERE
Two dice are rolled simultaneously. Given that one die shows a "4", what is
the probability that the total on the uppermost faces of the two dice is "7"?

Answear (2/11):
HERE

puts norm_prob {
    d1 = die; d2 = die
    guard d1 == 4 || d2 == 4
    d1 + d2 == 7
}.probability(true)

puts <<HERE

The same experiment using a simulation (t = 10s):
HERE
puts collecting(loop_t 10) {
    d1 = die; d2 = die
    guard d1 == 4 || d2 == 4
    d1 + d2 == 7
}.normalize.probability(true)

