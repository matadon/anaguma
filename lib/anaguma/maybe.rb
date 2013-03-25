module Anaguma
    class Maybe
        def initialize(state)
            @state = state
        end

        def result
            @state
        end

        def method_missing(method, *args, &block)
            return(self.class.new(nil)) if @state.nil?
            self.class.new(@state.send(method, *args, &block))
        end
    end
end
