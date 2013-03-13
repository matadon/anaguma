module Anaguma
    module ActiveRecord
        class Query
            attr_reader :_relation

            def initialize(relation)
                @_relation = relation
            end

            # @_relation = relation unless relation.is_a?(self.class) 
            # @_relation ||= relation._relation

            def select(value = nil)
                value = value.to_s if value.is_a?(Symbol)
                self.class.new(@_relation.select(value))
            end

            def from(value = nil)
                self.class.new(@_relation.from(value.to_s))
            end

            def joins(*args)
                self.class.new(@_relation.joins(*args))
            end

            def where(*args)
                args = [{}] if args.empty?
                self.class.new(@_relation.where(*args))
            end

            def having(*args)
                args = [{}] if args.empty?
                self.class.new(@_relation.having(*args))
            end

            def group(*args)
                self.class.new(@_relation.group(*args))
            end

            def order(*args)
                self.class.new(@_relation.order(*args))
            end

            def limit(count = nil)
                self.class.new(@_relation.limit(count))
            end

            def offset(count = nil)
                self.class.new(@_relation.offset(count))
            end

            def to_sql
                @_relation.to_sql
            end

            def clause(key)
                case(key.to_s)
                when "from", "limit", "offset"
                    @_relation.send("#{key}_value")
                when "select", "joins", "group", "order"
                    @_relation.send("#{key}_values")
                when "where", "having"
                    @_relation.send("#{key}_values").map { |item|
                        item.respond_to?(:to_sql) ? item.to_sql : item }
                else
                    raise(NoMethodError,
                        "#{self.class} has no \"#{key}\" clause")
                end
            end
        end
    end
end
