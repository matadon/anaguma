require 'anaguma/delegation'

module Anaguma
    class MatchedTerm
        include Delegation

        attr_reader :term, :matchers

        delegate :operator, :value, :quoting, :not?, :plaintext, :to_s,
            :left, :right, to: :term

        def initialize(term)
            @term = term
            @rejected = false
            @matchers = []
        end

        def field
            @alias || @term.field
        end

        def alias(name)
            @alias = name.to_s
            self
        end

        def reject!
            @rejected = true
            self
        end

        def rejected?
            @rejected == true
        end

        def matched?
            @matchers.count > 1
        end
    end
end
