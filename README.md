
Introduction
============

rb_probdsl offers simple discrete probabilistic programming support using 
delimited continuations in ruby.

Installation
============

## Install Gem

rb_probdsl is available via rubygems.org and be installed using rubygems:

    $ gem install rb_probdsl

## Install From Source

Before installing rb_probdsl, you need to install it's dependencies:

- rb_prob (monadic probabilistic programming library):
  install from source: http://github.com/urso/rb_prob  
  or via gem:

    $ gem install rb_prob


- rb_delimcc (delimited continuations for ruby):
  install from source: http://github.com/urso/rb_delimcc  
  or via gem:

    $ gem install rb_prob

now install rb_probdsl itself.

1. get the source 
    - from github: 

        $ git clone git://github.com/urso/rb_probdsl.git

    - or download zip file from http://github.com/urso/rb_probdsl/zipball/master
    - or download tarball from http://github.com/urso/rb_probdsl/tarball/master
      
2. install the gem (in source directory):

    $ gem build rb_probdsl.gemspec
    $ sudo gem install rb_probdsl

Usage:
======

To use rb_probdsl you need to use rubygems and require the library:

    require 'rubygems'

    require 'probdsl'
    include ProbDSL # optional, but will save some typing

For usage examples have a look into the examples directory.

Evaluation Strategies:
======================

Instead of computing the probability distributions directly an unevaulated
decision tree is build and only the root is returned.

On that tree different evaluation strategies may be applied. Implemented so
far are:

    run_prob { ... }          # returns an unevaluated tree

    prob { ... }              # will evaluate probabilistic code block
                              # to full probability distribution.

    norm_prob { ... }      # like prob[A], but will normalize and filter out
                           # nil values from the distribution.
                           # usefull when doing bayesian inference

    pick { ... }           # randomly samples a value from given
                           # probabilistic code block.
                           # This is linear in the number of random
                           # variables to be visited.

    collect(pred, tree)    # logically samples values from unevaluated tree
                           # until the given predicate returns false.
                           # Due to the fact, that the tree is build lazily
                           # sampling a value from the tree is O(N) with N being
                           # the number random variables to visit.

                            
    collecting(pred) { ... } # uses collect to evaluate given context

    loop_k(k), loop_t(time)  # predefined predicates to be used with
                             # collect/collecting evaluators

Furthermore the unevaluated tree instances provide the following functions:

    <tree>.eval            # computes a probability distribution from 
                           # unevaluated lazy tree

    <tree>.eval_pick       # randomly samples a value from tree.
                           # This sampling is done in O(N) steps with
                           # N being the number of random variables to visit

    <tree>.flatten         # flattens a tree and computes probabilities.
                           # use with <tree>.to_d to improve runtime by 
                           # evaluating subtrees first
                
    <tree>.to_d            # to_d will inject the <tree> into the current
                           # probabilistic block. using flatten first on that
                           # tree and then to_d subtree shared between
                           # variables can be precomputed to save space and
                           # time.

Some simple examples can be found in "examples/test.rb"

Examples
========

The 'examples' directory contains documented examples describing the problem and
solution with forumlas and code. It is recommended to read them to get a
feeling for how rb_probdsl and probabilistic programming works.
These examples are (a more or less) direct translation from the examples found
in the rb_prob package, so you may want to compare these side by side.

Recommended reading order:

- examples/diagnosis.rb  # most basic bayesian inference example
- examples/montyhall.rb  # monty hall problem/paradox
- examples/alarm.rb      # example from Artificial Intelligence - A Modern Approach
- examples/coins.rb      # about optimizing computations
- example/spamplan.rb    # a simple spam filter using a mix of
                         # probdsl and the monadic interface

