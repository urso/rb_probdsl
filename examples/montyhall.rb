
require 'rubygems'

require 'probdsl'
include ProbDSL

# the monty hall problem is a simple game show based probability puzzle with
# a puzzling outcome :)
#
# Suppose you are on a game show and you are given the choice of 3 doors.
# Behind one of these doors is the price and behind the others a goat. Only the
# moderator knows behind which door the price is and will open one door with a
# goat after you did your first choice. Next you can choose if you want to
# switch doors or not.
#
# Question:
# What is the best strategie? Stay or switch?
# What are the probabilities of winning for each of these strategies?
#

# first we want to encode our state.
#
# these are the doors one can choose from: 
$doors = [:A, :B, :C]

# and this the game's current state
class State
    attr_accessor :prize, # door the prize is behind
                  :open,  # door opened by host
                  :chosen # door currently chosen by player

    def initialize(p,c,o)
        @prize  = p
        @chosen = c
        @open   = o
    end

    def testWinner 
        if @prize == @chosen 
            :Winner
        else
            :Looser
        end
    end
end

# Let us encode the problem with random variables:
#
# P  = doors : door prize was put behind
# C1 = doors : the door chosen in the first round by player
# O  = doors :  the door opened by show's host
#

# first step: let's hide the price
# P(P = A) = 1/3
# P(P = B) = 1/3
# P(P = C) = 1/3
def hide
    uniform $doors
end

# and then let the player choose one door:
# P(C1 = A) = 1/3
# P(C1 = B) = 1/3
# P(C1 = C) = 1/3
def choose
    uniform $doors
end

# compute probability distribution of host opening a specific door
# given the event P and C1:
# P(O|C1,P)
# with O != C1 and O != P
def open(hidden, chosen)
    uniform($doors - [hidden, chosen])
end

# play the first round (until game host will open a door)
def firstRound
    p = hide
    c = choose
    State.new p, c, open(p,c)
end

# finally implement strategie 'stay'
def stay(s)
    s
end

# and strategy 'switch' choosing a door C2 with
# C2 != O and C2 != C1.
# find P(C2|O, C1, P)
def switch(s)
    uniform(($doors - [s.open, s.chosen]).map {|d| 
        State.new s.prize, d, s.open
    })
end

# print some results
p 'strategy stay:'
puts(prob { stay(firstRound).testWinner })

p 'strategy switch:'
puts(prob { switch(firstRound).testWinner })

