module Anaguma
    class MergingBuilder
        def initialize(state, *binds)
            @root = state
            @branches = []
            @binds = binds.flatten.map(&:to_s)
        end

        def merge(predicate)
            return(@root) if @branches.empty?
            head, *tail = @branches
            head.merge(predicate, *tail)
        end

        def push(*queries)
            @branches.push(*queries)
            self
        end

        def method_missing(method, *args, &block)
            return(super) unless @binds.include?(method.to_s)
            @branches.push(@root.send(method, *args, &block))
            self
        end
    end
end
