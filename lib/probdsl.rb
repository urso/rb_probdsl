
require 'rubygems'

require 'delimcc'
require 'prob'

module ProbDSL
    include DelimCC
    include Probably

    class PValue
        def initialize(v)
            @value = v
        end

        def reify
            Probably.mkState @value
        end

        def pick
            @value
        end
    end

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
            d = @fn.call
            m,p = d.pick
            k = m[0]
            v = m[1]
            tmp = k.call v
            tmp.pick
        end
    end

    def run_prob(&blk)
        reset {
            v = blk.call
            PValue.new v
        }
    end

    def prob(&blk)
        run_prob(&blk).reify
    end

    def normalizedProb(&blk)
        prob(&blk).normalize
    end

    def pick(&blk)
        run_prob(&blk).pick
    end

    def collect(pred, tree)
        m = Hash.new(0)
        while (pred.call)
            x = tree.pick
            m[x] += 1.0
        end
        Distribution.new :MAP, m
    end

    def collecting(pred, &blk)
        collect(pred, run_prob(&blk))
    end

    def loop_k(k)
        tmp = k
        proc {
            r = tmp > 0
            tmp-=1
            r
        }
    end

    def loop_t(s)
        start = Time.now
        proc {
            (Time.now - start) < s
        }
    end

    def dist(data)
        shift { |k|
            PChoice.new do
                m = Hash.new(0)
                data.each do |p,d|
                    tmp = [k,d]
                    m[tmp] += p
                end

                Distribution.new :MAP, m
            end
        }
    end

    def uniform(data)
        dist(data.map {|x| [1, x]})
    end

    def flip(x, *data)
        case data.length
        when 0
            dist [[x, true], [1 - x, false]]
        when 1
            dist [[x, data[0]], [1 - x, nil]]
        when 2
            dist [[x, data[0]], [1 - x, data[1]]]
        else
            raise 'illegal number of arguments'
        end
    end
end

