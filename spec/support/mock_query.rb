require 'anaguma/builder'

module Anaguma
    class MockQuery
        def self.builder(base)
            Anaguma::Builder.new(base, :condition)
        end

        def self.monadic_query_methods
            %w(condition)
        end

        def initialize(condition = nil)
            @condition = condition
        end

        def condition(term)
            updated = [ @condition, term.to_s ].compact.join(" ").strip
            self.class.new(updated)
        end

        def to_s
            @condition.to_s
        end

        def ==(other)
            to_s == other.to_s
        end

        def merge(predicate, *queries)
            queries = queries.flatten.unshift(self)
            return(queries.first.to_s) if (queries.length < 2)
            merged = queries.map(&:to_s).unshift(predicate).join(" ")
            self.class.new("(#{merged})")
        end
    end
end
