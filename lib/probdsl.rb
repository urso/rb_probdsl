
require 'rubygems'

require 'delimcc'
require 'prob'

module ProbDSL
    include DelimCC
    include Probably

    class PDistribution < Distribution
        def eval
            self.dep do |m|
                m.call.eval
            end
        end

        def eval_pick
            cont,* = pick
            cont.call.eval_pick
        end

        def flatten
            self.dep do |m|
                m.call.flatten
            end
        end

        def to_d
            tmp = self.map { |f|
                f.call
            }
            shift do |cont|
                tmp.map {|f|
                    proc { cont.call(f) }
                }
                # self.map { |f|
                #     proc { cont.call(f.call) }
                # }
            end
        end
    end

    class PNone
        def eval;      nil; end
        def eval_pick; nil; end
        def flatten;   nil; end

        def call;      nil; end

        def to_d
            nil
        end
    end

    class PValue
        attr_reader :value

        def initialize(v); @value = v; end
        def eval;          PDistribution.mk_const @value; end
        def eval_pick;     @value; end

        def flatten
            PDistribution.mk_const self
        end

        def call;         @value end

        def eql?(b)
            @value = b.value
        end

        def hash
            @value.hash
        end

        def to_d
            @value
        end
    end

    PNil = PNone.new

    def run_prob(&blk)
        reset {
            value = blk.call
            if value == nil
                PNil
            else
                PValue.new value
            end
        }
    end

    def prob(&blk)
        run_prob(&blk).eval
    end

    def norm_prob(&blk)
        prob(&blk).normalize
    end

    def pick(&blk)
        run_prob(&blk).eval_pick
    end

    def collect(pred, tree)
        tmp = Hash.new(0)
        n   = 0
        while (pred.call)
            tmp[tree.eval_pick] += 1.0
            n += 1
        end
        [PDistribution.new(:MAP, tmp), n]
    end

    def collecting(pred, &blk)
        collect(pred, run_prob(&blk))
    end

    def loop_k(ktimes)
        tmp = ktimes
        proc {
            ret = tmp > 0
            tmp-=1
            ret
        }
    end

    def loop_t(seconds)
        start = Time.now
        proc {
            (Time.now - start) < seconds
        }
    end

    def guard(bool)
        if !bool
            shift do |cont|
                PNil
            end
        end
    end

    def dist(data)
        shift do |cont|
            map = Hash.new 0
            data.each do |prob, value|
                tmp = proc { cont.call value }
                map[tmp] = prob
            end

            PDistribution.new :MAP, map
        end
    end

    def uniform(data)
        dist(data.map {|x| [1, x]})
    end

    def flip(prob, *data)
        case data.length
        when 0
            dist [[prob, true], [1 - prob, false]]
        when 1
            dist [[prob, data[0]], [1 - prob, nil]]
        when 2
            dist [[prob, data[0]], [1 - prob, data[1]]]
        else
            raise 'illegal number of arguments'
        end
    end
end

