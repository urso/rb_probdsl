
require 'rubygems'

require 'probdsl'
include ProbDSL

# 
# Problem: 
# Given a positive or negative test for a specific illness we want to know the
# probability for being ill or healthy.
#
# Suppose the random variables I and T are given with I = {Ill, Healthy}
# being the health status and T = {Negative, Positive} the test result.
#
# It is known that the probability of being 'ill' is 1 in a 1000,
# thus:
# P(I = Ill) = 0.001 and P(I = Healthy) = 0.999
#
# Furthermore we do know that the test has an accuracy of 99%, thus
# P(T = Positive | I = Ill ) = 0.99
# P(T = Negative | I = Ill ) = 0.01
# P(T = Positive | I = Healthy ) = 0.01
# P(T = Negative | I = Healthy ) = 0.99
#
# Task:
# compute the probability of being 'ill', given the test was positive.
# Using bayes rule:
#
# P(T, I) = P(T|I) * P(I) = P(I|T) * P(T)
#
# =>
#
#           P(T |I) * P(I)
# P(I|T) = ---------------- = < P(T|I) * P(I) >
#                P(T)
#
#

PFalseNegative = 0.01 # constant for P( T | I = Ill)
PFalsePositive = 0.01 # constant for P( T | I = Healthy)

# define: P(I)
def p_disease
    flip 0.001, :ILL, :HEALTHY
end

# P(T|I)
def p_test(i)
    flip(i == :ILL ? PFalseNegative : 1 - PFalsePositive,
           :Negative, :Positive)
end

p "P(I|T=Positive)"
puts norm_prob {
    i = p_disease
    if p_test(i) == :Positive
        i
    else
        nil
    end
}

