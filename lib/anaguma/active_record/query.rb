require "active_record"
require "anaguma/builder"
require "anaguma/query"

module Anaguma
    module ActiveRecord
        class Query < Anaguma::Query
            OPERATORS = { lt: '<', gt: '>', lte: '<=', gte: '>=', ne: '!=',
                notlike: '!=', eq:'=', like:'=' }

            chain :select, :from, :joins, :includes, :where, :having,
                :group, :order, :reorder, :limit, :offset
            
            def self.monadic_methods
                %w(select limit offset group having where compare)
            end

            def initialize(scope)
                return(super) if scope.is_a?(self.class)
                return(super) if scope.is_a?(::ActiveRecord::Relation)
                use_scope(::ActiveRecord::Relation.new(scope,
                    scope.arel_table))
            end

            def relation
                @scope
            end

            def clear
                self.class.new(@scope.only)
            end

            def compare(*args)
                field, operator, value = parse_args_for_compare(*args)
                quoted_field = @scope.connection.quote_column_name(field)
                where("#{quoted_field} #{OPERATORS[operator]} ?", value)
            end

            def to_sql
                @scope.to_sql
            end

            def clause(key)
                case(key.to_s)
                when "from", "limit", "offset"
                    @scope.send("#{key}_value")
                when "select", "joins", "includes", "group", "order"
                    @scope.send("#{key}_values").map(&:to_s)
                when "where", "having"
                    @scope.send("#{key}_values").map { |item|
                        item.respond_to?(:to_sql) ? item.to_sql : item }
                else
                    raise(NoMethodError,
                        "#{self.class} has no \"#{key}\" clause")
                end
            end

            def merge(predicate, *others)
                clauses = Hash.new { |h, k| h[k] = Array.new }
                others.flatten.unshift(self).each do |query|
                    merge_unpredicated_clauses(clauses, query)
                    combined_where_clause_for_query = combine_and_wrap(
                        :and, query.clause(:where))
                    clauses[:where].concat(combined_where_clause_for_query)
                    combined_having_clause_for_query = combine_and_wrap(
                        :and, query.clause(:having))
                    clauses[:having].concat(combined_having_clause_for_query)
                end

                clauses[:where] = combine_and_wrap(predicate, clauses[:where])
                clauses[:having] = combine_and_wrap(predicate, clauses[:having])
                self.class.new((build_new_relation_from_clauses(clauses)))
            end

            def tuples(reload = false)
                @_tuples = nil if reload
                @_tuples ||= connection.select_all(to_sql).map do |tuple|
                    tuple.each do |key, value|
                        next unless (column = @scope.columns_hash[key])
                        tuple[key] = column.type_cast(value)
                    end
                end
            end

            def count(reload = false)
                @_count = nil if reload
                @_count ||= @scope.count
            end

            def ==(other)
                return(false) unless other.respond_to?(:to_sql)
                to_sql == other.to_sql
            end

            def to_sql
                @scope.to_sql
            end

            private

            def connection
                @scope.connection
            end

            def merge_unpredicated_clauses(result, query)
                result[:select].concat(query.clause(:select))
                result[:joins].concat(query.clause(:joins))
                result[:includes].concat(query.clause(:includes))
                result[:group].concat(query.clause(:group))
                result[:order].concat(query.clause(:order))
                result[:from] = query.clause(:from)
                result[:limit] = query.clause(:limit)
                result[:offset] = query.clause(:offset)
                result
            end

            def build_new_relation_from_clauses(clauses)
                relation = ::ActiveRecord::Relation.new(@scope.klass,
                    @scope.table)
                builder = Builder.new(relation, %w(select from joins includes
                    where having group order limit offset))
                builder.select(clauses[:select].uniq) \
                    unless clauses[:select].empty?
                builder.from(clauses[:from]) \
                    unless clauses[:from].nil?
                builder.joins(*clauses[:joins].uniq) \
                    unless clauses[:joins].empty?
                builder.includes(*clauses[:includes].uniq) \
                    unless clauses[:includes].empty?
                builder.where(*clauses[:where].uniq) \
                    unless clauses[:where].empty?
                builder.having(*clauses[:having].uniq) \
                    unless clauses[:having].empty?
                builder.group(*clauses[:group].uniq) \
                    unless clauses[:group].empty?
                builder.order(*clauses[:order].uniq) \
                    unless clauses[:order].empty?
                builder.limit(clauses[:limit]) \
                    unless clauses[:limit].nil?
                builder.offset(clauses[:offset]) \
                    unless clauses[:offset].nil?
                builder.result
            end

            def combine_and_wrap(separator, items)
                separator = (separator == :or) ? " OR " : " AND "
                items = items.flatten.compact.reject(&:empty?)
                return([]) if (items.length == 0)
                return([ items.first ]) if (items.length == 1)
                [ items.map { |i| "(#{i})" }.join(separator) ]
            end
        end
    end
end
