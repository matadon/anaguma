require 'kusuri/delegation'
require 'kusuri/mongoid/query'

# def aggregation_with_criteria
#     combined_aggregation = @_aggregation.dup
#     return(combined_aggregation) if @_criteria.selector.empty?
#     combined_aggregation.push("$match" => @_criteria.selector)
# end

module Kusuri
    module Mongoid
        class AggregateQuery < Query
            attr_reader :_aggregate

            def self.builder(base)
                Kusuri::Builder.new(base, :where, :compare, :unwind,
                    :project, :group, :fields, :sort)
            end

            def self.merge(boolean, *queries)
                return(new(queries[0]._criteria, queries[0]._aggregate)) \
                    if (queries.length == 1)

                selectors = []
                criteria = queries.map(&:_criteria)
                without_conditions = criteria.inject(nil) do |memo, item|
                     selectors.push(item.selector) unless item.selector.empty?
                     empty_criteria = item.clone
                     empty_criteria.selector = Origin::Selector.new
                     memo ? memo.merge(empty_criteria) : empty_criteria
                end

                aggregates = queries.inject({}) { |memo, query|
                    memo.merge(query._aggregate) }
                new(without_conditions.where("$#{boolean}" => selectors),
                    aggregates)
            end

            def initialize(criteria, aggregate = {})
                super(criteria)
                @_aggregate = aggregate
            end

            def unwind(*fields)
                chain(unwind: (@_aggregate[:unwind] || []).concat(fields))
            end

            def project(*fields)
                projection = (fields.last.is_a?(Hash) ? fields.pop : {})
                fields.each { |f| projection[f] = 1 }
                chain(project: (@_aggregate[:project] || {}).merge(projection))
            end

            def group(fields = {})
                chain(group: (@_aggregate[:group] || {}).merge(fields))
            end

            def fields(fields = {})
                chain(fields: (@_aggregate[:fields] || {}).merge(fields))
            end

            def sort(fields = {})
                chain(sort: (@_aggregate[:sort] || {}).merge(fields))
            end

            def where(conditions)
                self.class.new(@_criteria.where(conditions), @_aggregate)
            end

            def skip(count = 0)
                chain(skip: count)
            end

            def limit(count = 10)
                chain(limit: count)
            end

            def instances(reload = false)
                raise(NotImplementedError,
                    "AggregateQuery only returns tuples, not instances.")
            end

            def tuples(reload = false)
                @_tuples = nil if reload
                @_tuples ||= aggregate(*pipeline).map { |tuple|
                    tuple.reject { |k, v| k == '_id' } }
            end

            def count(reload = false)
                counter = pipeline.push({ "$group" => { _id: "1",
                    total: { "$sum" => 1 } } })
                @_count = nil if reload
                @_count ||= (aggregate(*counter).first || {})['total'].to_i
            end

            def empty?
                count == 0
            end

            def each(&block)
                instances.each(&block)
            end

            def to_s
                @_criteria.inspect
            end

            def pipeline
                result = []
                (@_aggregate[:unwind] || []).each { |field|
                    result.push("$unwind" => field) }
                result.push("$project" => @_aggregate[:project]) \
                    if @_aggregate[:project]
                collated_group = (@_aggregate[:fields] || {}) \
                    .merge(_id: @_aggregate[:group])
                result.push("$group" => collated_group) \
                    if (@_aggregate[:fields] or @_aggregate[:group])
                result.push("$match" => @_criteria.selector) \
                    unless @_criteria.selector.empty?
                result.push("$sort" => @_aggregate[:sort]) \
                    if @_aggregate[:sort]
                result.push("$skip" => @_aggregate[:skip]) \
                    if @_aggregate[:skip]
                result.push("$limit" => @_aggregate[:limit]) \
                    if @_aggregate[:limit]
                result
            end

            private

            def chain(updates = {})
                self.class.new(@_criteria, @_aggregate.merge(updates))
            end

            def stringify_hash(input)
                input.inject({}) { |m, (k, v)| m[k.to_s] = v; m }
            end
        end
    end
end
