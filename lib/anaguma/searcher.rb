require 'anaguma/builder'
require 'anaguma/consumable_term'
require 'anaguma/search_parser'

module Anaguma
    class Searcher
        def self.parser(parser)
            @parser = parser
            self
        end

        def self.query_class(query_class)
            @query_class = query_class
            self
        end

        def self.rule(name = nil, &block)
            (@rules ||= []).push(create_unique_method(:rule, name, &block))
            self
        end

        private

        def self.create_unique_method(group, name = nil, &block)
            method_name = "_#{group}"
            method_name << "_#{name}" if name
            method_name << "_#{Time.now.to_i}#{Time.now.usec}"
            define_method(method_name, &block)
            private(method_name)
            method_name
        end

        public

        def self.filter(*args, &block)
            rule(:filter) { |term| term.consume! unless block.call(term) }
            self
        end

        def self.permit(*fields)
            fields = fields.flatten.map(&:to_s).unshift(nil)
            filter { |term| fields.include?(term.field) }
            self
        end

        def initialize(scope, parser = nil)
            @scope = Builder.new(query_class.new(scope), *monadic_methods)
            @builder = @scope
            @parser = parser
        end

        def parser
            @_parser ||= (@parser \
                or inherited_attribute(:parser).compact.first \
                or Anaguma::SearchParser).new
        end

        def search(search)
            parse(search.to_s)
        end

        def query_class
            @_query_class ||= inherited_attribute(:query_class).compact.first \
                or raise(RuntimeError, "No query_class specified.")
        end

        def scope
            @scope.result or raise(RuntimeError, "No scope specified.")
        end

        private

        def parse(search)
            compile(parser.parse(search)) || query_class.new(scope)
        end

        def rules
            @rules ||= inherited_attribute(:rules).compact.first \
                or raise("No rules defined for #{self}")
        end

        def compile(root)
            subqueries = root.inject([]) do |memo, node|
                next(memo.push(compile(node))) if node.group?
                memo.concat(apply_rules(rules, node))
            end
            head = subqueries.shift
            return(head) if subqueries.empty?
            head.merge(root.predicate, *subqueries)
        end

        def apply_rules(rules, node)
            term = ConsumableTerm.new(node)
            rules.inject([]) do |result, rule|
                return(result) if term.consumed?
                @builder = Builder.new(query_class.new(scope),
                    *monadic_methods)
                send(rule, term)
                result.push(@builder.result)
            end
        end

        def inherited_attribute(name)
            klass = self.class
            result = []
            while(klass)
                result.push(klass.instance_variable_get("@#{name}"))
                klass = klass.superclass
            end
            result
        end

        def monadic_methods
            @_monadic_methods ||= query_class \
                .monadic_methods.map(&:to_s)
        end

        def method_missing(method, *args, &block)
            return(super) unless monadic_methods.include?(method.to_s)
            @builder.send(method, *args, &block)
            self
        end
    end
end
