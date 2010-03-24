
require 'rubygems'

require 'probdsl'
include ProbDSL

puts "test1"

puts(prob {
    d = uniform [1,2,3,4,5,6]
    d
})

p 'test2'

def die
    uniform 1..6
end

def dice
    d1 = die
    d2 = die
    [d1, d2]
end

puts(prob {
    d1 = die
    d2 = die
    d1 + d2
})

p 'test3'

puts(prob{ die + die })

p 'test4'

puts(pick {
    dice
})

p 'test5'

puts(prob {
    d1, d2 = dice
    d1 + d2
})

p 'test6'
tmp = prob{ dice }

puts(prob {
    d1, d2 = dist(tmp) # this time use already evaluated distribution
    d1 + d2
})

p 'test7'

puts(collecting(loop_k 1000) {
    die + die
})

p 'test8'

puts(collecting(loop_t 30) {
    die + die
})

