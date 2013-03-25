require 'mongoid'
require "anaguma/query"

module Anaguma
    module Mongoid
        class Query < Anaguma::Query
            chain :where, :limit, :skip

            def self.monadic_methods
                %w(where compare)
            end

            def criteria
                @scope
            end

            def clear
                self.class.new(::Mongoid::Criteria.new(@scope.klass))
            end

            def compare(*args)
                field, operator, value = parse_args_for_compare(*args)
                return(where(field => value)) if (operator == :eq)
                where(field => { "$#{operator}" => value })
            end

            def aggregate(*pipeline)
                collection.aggregate(*pipeline)
            end

            def offset(count)
                skip(count)
            end

            def tuples(reload = false)
                @_tuples = nil if reload
                @_tuples ||= @scope.query.to_a
            end

            def count(reload = false)
                @_count = nil if reload
                @count ||= @scope.count
            end

            def merge(boolean, *queries)
                self.class.new(merge_criteria(boolean, 
                    queries.flatten.unshift(self).map(&:criteria)))
            end

            private

            def merge_criteria(boolean, criteria)
                return(criteria.first.clone) if (criteria.length == 1)
                selectors = criteria.map(&:selector).reject(&:empty?)
                merged_criteria = criteria.first.clone
                merged_criteria.selector = Origin::Selector.new
                return(merged_criteria) if selectors.empty?
                merged_criteria.where("$#{boolean}" => selectors)
            end

            def collection
                @scope.collection
            end
        end
    end
end
