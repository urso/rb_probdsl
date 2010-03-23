
require 'rubygems'

require 'probdsl'
include ProbDSL

# Alarm example from "Artificial Intelligence - A Modern Approach" by Russel
# and Norvig Page 493 cc.
#
# Suppose you have a new fairly reliable burglar alarm at home but occasionally
# it responds to minor earthquakes. You also have two neighbors John and Mary,
# who have promised to call you at work when they hear the alarm. John always
# calls when he hears the alarm, but sometimes confuses the telephone ringing
# with the alarm and calls then, too. Mary, on the other hand, is too much in
# loud music and sometimes misses the alarm altogether.
#
# So the bayesian network will be:
#
#           B         E
#            \       /
#            _\|   |/_
#                A
#             /    \
#           |/_    _\|
#          J          M
#
#  with probabilities:
#  P(B) = 0.001
#  P(E) = 0.002
#
#  P(A| B=true, E=true)   = 0.95
#  P(A| B=true, E=false)  = 0.94
#  P(A| B=false, E=true)  = 0.29
#  P(A| B=false, E=false) = 0.001
#
#  P(J| A=true)  = 0.9
#  P(J| A=false) = 0.05
#
#  P(M| A=true)  = 0.7 
#  P(M| A=false) = 0.01
#
#  where B = burglar, E = earthquake, A = alarm, J = John calls and 
#  M = Mary calls
#

# first let's encode the probabilities from the network
# P(B)
def p_burglary
    flip(0.001, :B, :notB)
end

# P(E)
def p_earthquake
    flip(0.002, :E, :notE)
end

# P(A|B = b,E = e)
def p_alarm(b,e)
    pAlarmTable = {
        [:B, :E] => 0.95,
        [:B, :notE] => 0.94,
        [:notB, :E] => 0.29,
        [:notB, :notE] => 0.001
    }
    flip(pAlarmTable[[b,e]], :A, :notA)
end

# P(J|A = a)
def p_john(a)
    flip( a == :A ? 0.9 : 0.05, :J, :notJ)
end

# P(M|A = a)
def p_mary(a)
    flip( a == :A ? 0.7 : 0.01, :M, :notM)
end

p "joint probability:"
p(prob do
    b = p_burglary
    e = p_earthquake
    a = p_alarm(b,e)
    [b,e,a,p_john(a), p_mary(a)]
end)

p "P(B|John=true, Mary=true):"
p(normalizedProb do
    b = p_burglary
    e = p_earthquake
    a = p_alarm(b,e)
    if (p_john(a) == :J && p_mary(a) == :M)
        b
    else
        nil
    end
end)

p "P(A|John=true, Mary=true)"
p(normalizedProb do
    b = p_burglary
    e = p_earthquake
    a = p_alarm(b, e)
    if p_john(a) == :J && p_mary(a) == :M
        a
    else
        nil
    end
end)

# john and mary tell us for sure, the alarm went of and we know
# that is true...
p "P(B|John=true, Mary=true, Alarm=true)"
p(normalizedProb do
    b = p_burglary
    e = p_earthquake
    a = p_alarm(b,e)
    if (a == :A && p_john(a) == :J && p_mary(a) == :M)
        b
    else
        nil
    end
end)

# what is the probability john will call, if mary called?
p "P(John|Mary=true)"
p(normalizedProb do
    b = p_burglary
    e = p_earthquake
    a = p_alarm(b,e)
    if (p_mary(a) == :M)
        p_john(a)
    else
        nil
    end
end)

# and probability mary will call, if john did
p "P(Mary|John=true)"
p(normalizedProb do
    b = p_burglary
    e = p_earthquake
    a = p_alarm(b,e)
    if (p_john(a) == :J)
        p_mary(a)
    else
        nil
    end
end)

