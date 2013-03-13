module Anaguma
    class Builder
        attr_reader :result

        def initialize(state, *binds)
            @state, @binds = state, binds.flatten.map(&:to_sym)
        end

        def result
            @state
        end

        def eval(&block)
            return(instance_eval(&block)) if (block.arity < 1)
            yield(self)
        end

        def method_missing(method, *args, &block)
            output = @state.send(method, *args, &block)
            return(output) unless @binds.include?(method)
            @state = output
            self
        end
    end
end
