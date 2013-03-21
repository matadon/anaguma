require 'mongoid'

module Anaguma
    module Mongoid
        class Query
            include Enumerable

            attr_reader :_criteria

            def self.monadic_query_methods
                %w(where compare)
            end

            def initialize(scope)
                @_criteria = scope unless scope.is_a?(self.class) 
                @_criteria ||= scope._criteria
            end

            def where(conditions = {})
                self.class.new(@_criteria.where(conditions))
            end

            def compare(term, options = {})
                operator = (options[:operator] or "$#{term.operator}")
                value = (options[:value] or term.value)
                field = (options[:field] or term.field)

                return(where(build_condition(field, operator, value))) \
                    unless (options[:any] or options[:all])

                conditions = []
                builder = lambda { |f| build_condition(f, operator, value) }
                any_predicate = term.not? ? "$and" : "$or"
                conditions << { any_predicate => options[:any] \
                    .map(&builder) } if options[:any]
                all_predicate = term.not? ? "$or" : "$and"
                conditions << { all_predicate => options[:all] \
                    .map(&builder) } if options[:all]
                where(*conditions)
            end

            def aggregate(*pipeline)
                collection.aggregate(*pipeline)
            end

            def limit(count)
                self.class.new(@_criteria.limit(count))
            end

            def skip(count)
                self.class.new(@_criteria.skip(count))
            end

            def offset(count)
                skip(count)
            end

            def tuples(reload = false)
                @_tuples = nil if reload
                @_tuples ||= @_criteria.query.to_a
            end

            def count(reload = false)
                @_count = nil if reload
                @count ||= @_criteria.count
            end

            def empty?
                count == 0
            end

            def each(&block)
                tuples.each(&block)
            end

            def merge(boolean, *queries)
                self.class.new(merge_criteria(boolean, 
                    queries.flatten.unshift(self).map(&:_criteria)))
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

            def build_condition(field, operator, value)
                case(operator)
                when "$eq"
                    { field => value }
                when "$like"
                    pattern = value.gsub(/(\*|\?|[^\*\?]+)/).each do |match|
                        next(".*") if (match == "*")
                        next("?") if (match == "?")
                        Regexp.quote(match)
                    end
                    regex = Regexp.new("^#{pattern}", Regexp::IGNORECASE)
                    { field => { "$regex" => regex } }
                else
                    { field => { operator => value } }
                end
            end

            def collection
                @_criteria.collection
            end
        end
    end
end
