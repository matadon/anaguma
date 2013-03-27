require 'anaguma/builder'
require 'anaguma/query'

module Anaguma
    class MockQuery < Anaguma::Query
        def self.monadic_methods
            %w(condition compare merge clear)
        end

        def initialize(scope = nil)
            @scope = scope
        end

        def condition(term)
            updated = [ @scope, term.to_s ].compact.join(" ").strip
            self.class.new(updated)
        end

        def compare(term, options = {})
            field, operator, value = parse_args_for_compare(term, options)
            negation = term.negated? ? "!" : ""
            quoted_value = "#{term.left_quote}#{value}#{term.right_quote}"
            condition("#{negation}#{field}:#{operator}:#{quoted_value}")
        end

        def clear
            self.class.new
        end

        def to_s
            @scope.to_s
        end

        def ==(other)
            to_s == other.to_s
        end

        def merge(predicate, *queries)
            queries = queries.flatten.unshift(self)
            return(queries.first) if (queries.length < 2)
            merged = queries.map(&:to_s).unshift(predicate).join(" ")
            self.class.new("(#{merged})")
        end
    end
end
