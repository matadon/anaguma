require "active_record"
require "anaguma/builder"

module Anaguma
    module ActiveRecord
        class Query
            include Enumerable

            attr_reader :relation, :_format

            def self.monadic_query_methods
                %w(select limit offset group having where compare)
            end

            def initialize(scope, format = nil)
                if(scope.is_a?(self.class))
                    @relation = scope.relation
                    @_format = format || scope._format
                elsif(scope.is_a?(::ActiveRecord::Relation))
                    @relation = scope
                    @_format = format || :instances
                else
                    @relation = ::ActiveRecord::Relation.new(scope,
                        scope.arel_table)
                    @_format = format || :instances
                end
            end

            def select(value = nil)
                value = value.to_s if value.is_a?(Symbol)
                chain(@relation.select(value))
            end

            def from(value = nil)
                chain(@relation.from(value.to_s))
            end

            def joins(*args)
                chain(@relation.joins(*args))
            end

            def includes(*args)
                chain(@relation.includes(*args))
            end

            def where(*args)
                args = [{}] if args.empty?
                chain(@relation.where(*args))
            end

            def having(*args)
                args = [{}] if args.empty?
                chain(@relation.having(*args))
            end

            def group(*args)
                chain(@relation.group(*args))
            end

            def order(*args)
                chain(@relation.order(*args))
            end

            def reorder(*args)
                chain(@relation.reorder(*args))
            end

            def limit(count = nil)
                chain(@relation.limit(count))
            end

            def offset(count = nil)
                chain(@relation.offset(count))
            end

            OPERATORS = {
              lt: '<',
              gt: '>',
              lte: '<=',
              gte: '>=',
              ne: '!=',
              notlike: '!=',
              eq:'=',
              like:'='
            }

            def compare(term = nil, options = {})
              return chain(@relation) unless term
              unquoted_field = options[:field] || term.field
              field = @relation.connection.quote_column_name(unquoted_field)
              value = options[:value] || term.value
              operator = (options[:operator] || term.operator)
              operator or raise(ArgumentError,
                "Cannot match term with operator #{term.operator}")

              return where(where_term_for(field, operator.to_sym, value)) \
                unless options[:any] || options[:all]

              builder = lambda { |f| where_term_for(f, operator.to_sym, value) }
              result = self
              if options[:any]
                predicate = term.not? ? :and : :or
                clauses = options[:any].map(&builder)
                combined = combine_and_wrap(predicate, clauses)
                result = result.where(combined)
              end
              if options[:all]
                predicate = term.not? ? :or : :and
                clauses = options[:all].map(&builder)
                combined = combine_and_wrap(predicate, clauses)
                result = result.where(combined)
              end
              return result
            end

            def to_sql
                @relation.to_sql
            end

            def clause(key)
                case(key.to_s)
                when "from", "limit", "offset"
                    @relation.send("#{key}_value")
                when "select", "joins", "includes", "group", "order"
                    @relation.send("#{key}_values")
                when "where", "having"
                    @relation.send("#{key}_values").map { |item|
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
                chain(build_newrelation_from_clauses(clauses))
            end

            def ==(other)
                return(false) unless other.respond_to?(:to_sql)
                to_sql == other.to_sql
            end

            def instances
                @relation.all
            end

            def tuples
                connection = @relation.connection
                connection.select_all(@relation.to_sql).map do |tuple|
                    tuple.each_pair do |key, value|
                        next unless (column = @relation.columns_hash[key])
                        tuple[key] = column.type_cast(value)
                    end
                    tuple
                end
            end

            def return_results_as(format)
                format = format.to_sym
                raise(ArgumentError, "Format must be :instances or :tuples") \
                    unless [:instances, :tuples].include?(format)
                chain(@relation, format)
            end

            def each(&block)
                return(@relation.each(&block)) if (@_format == :instances)
                tuples.each(&block)
            end

            def count
                @relation.count
            end

            def empty?
                @relation.empty?
            end

            private

            def chain(relation, format = nil)
                self.class.new(relation, format || @_format)
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

            def build_newrelation_from_clauses(clauses)
                relation = ::ActiveRecord::Relation.new(@relation.klass,
                    @relation.table)
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

            def where_term_for(field, operator, value)
              clause_before_condition = clause(:where)
              conditional = where("#{field} #{OPERATORS[operator]} ?", value)
              (conditional.clause(:where) - clause_before_condition).first
            end

        end
    end
end
