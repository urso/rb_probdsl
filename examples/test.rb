
require 'rubygems'

require 'probdsl'
include ProbDSL

p 'test1'

p(prob {
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

p(prob {
    d1 = die
    d2 = die
    d1 + d2
})

p 'test3'

p(prob{ die + die })

p 'test4'

p(pick {
    dice
})

p 'test5'

p(prob {
    d1, d2 = dice
    d1 + d2
})

p 'test6'
tmp = prob{ dice }

p(prob {
    d1, d2 = dist(tmp) # this time use already evaluated distribution
    d1 + d2
})

p 'test7'

p(collecting(loop_k 1000) {
    die + die
})

p 'test8'

p(collecting(loop_t 30) {
    die + die
})

