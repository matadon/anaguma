require 'anaguma/delegation'

module Anaguma
    class ConsumableTerm
        include Delegation

        attr_reader :term

        delegate :field, :operator, :value, :quoting, :negated?, :plaintext,
            :to_s, :quotes, to: :term

        def initialize(term)
            @term = term
            @consumed = false
        end

        def consume!
            @consumed = true
            self
        end

        def nom!
            consume!
        end

        def consumed?
            @consumed == true
        end
    end
end
