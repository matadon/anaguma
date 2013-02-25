require 'kusuri/builder'

module Kusuri
    class MockQuery
        def self.merge(predicate, *queries)
            return(queries.first.to_s) if (queries.length < 2)
            merged = queries.map(&:to_s).unshift(predicate).join(" ")
            new("(#{merged})")
        end

        def self.builder(base)
            Kusuri::Builder.new(base, :condition)
        end

        def initialize(condition = nil)
            @condition = condition
        end

        def condition(term)
            updated = [ @condition, term.to_s ].compact.join(" ")
            self.class.new(updated)
        end

        def to_s
            @condition.to_s
        end

        def ==(other)
            to_s == other.to_s
        end
    end
end
