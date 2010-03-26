
require 'rubygems'

require 'delimcc'
require 'prob'

module ProbDSL
    include DelimCC
    include Probably

    class PNone
        def reify
            nil
        end

        def pick
            nil
        end
    end

    PNil = PNone.new

    class PValue
        def initialize(v)
            @value = v
        end

        def reify
            Probably.mk_const @value
        end

        def pick
            @value
        end
    end

    # Tree Node in Decision tree.
    # All sub nodes are unevaluated, so tree expansion is lazy
    # and therefore different evaluation strategies may be implemented.
    class PChoice
        def initialize(&blk)
            @fn = blk
        end

        def reify
            d = @fn.call
            d.dep do |m|
                k = m[0]
                v = m[1]
                tmp = k.call(v)
                tmp.reify
            end
        end

        def pick
            dist = @fn.call
            picked,probability = dist.pick
            cont = picked[0]
            value = picked[1]
            cont.call(value).pick
        end
    end

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
        run_prob(&blk).reify
    end

    def norm_prob(&blk)
        prob(&blk).normalize
    end

    def pick(&blk)
        run_prob(&blk).pick
    end

    def collect(pred, tree)
        tmp = Hash.new(0)
        while (pred.call)
            tmp[tree.pick] += 1.0
        end
        Distribution.new :MAP, tmp
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
        shift { |cont|
            PChoice.new do
                map = Hash.new(0)
                data.each do |prob, dist|
                    map[[cont, dist]] += prob
                end

                Distribution.new :MAP, map
            end
        }
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

