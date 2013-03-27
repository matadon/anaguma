require 'anaguma/builder'
require 'anaguma/merging_builder'
require 'anaguma/maybe'
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

        def self.search_in_specific_fields(*args)
            options = args.last.is_a?(Hash) ? args.pop.dup : {}
            fields = Hash[args.flatten.map(&:to_s).zip]
            build_searchable_rule(options) do |term|
                throw(:skip) unless fields.has_key?(term.field)
                compare(term)
            end
        end

        def self.search_in_any_of(*args)
            options = args.last.is_a?(Hash) ? args.pop.dup : {}
            fields = args.flatten.map(&:to_s)
            allow_fields = Hash[[ options.delete(:field), 
                options.delete(:fields) ].flatten.compact.zip]
            build_searchable_rule(options) do |term|
                throw(:skip) unless (allow_fields.empty? \
                    or allow_fields.has_key?(term.field))
                any_of { fields.each { |f| compare(term, field: f) } }
            end
        end

        def self.search_in_all_of(*args)
            options = args.last.is_a?(Hash) ? args.pop.dup : {}
            fields = args.flatten.map(&:to_s)
            allow_fields = Hash[[ options.delete(:field), 
                options.delete(:fields) ].flatten.compact.zip]
            build_searchable_rule(options) do |term|
                throw(:skip) unless (allow_fields.empty? \
                    or allow_fields.has_key?(term.field))
                all_of { fields.each { |f| compare(term, field: f) } }
            end
        end

        def self.search_in(*args)
            options = args.last.is_a?(Hash) ? args.pop.dup : {}
            fields = Hash[args.flatten.map(&:to_s).zip]
            build_searchable_rule(options) do |term|
                return(compare(term)) if fields.has_key?(term.field)
                throw(:skip) unless term.field.nil?
                any_of { fields.keys.each { |f| compare(term, field: f) } }
            end
        end

        private

        #
        # FIXME: Preserve line number?
        #
        def self.build_searchable_rule(options, &block)
            if_condition = create_unique_method(:condition, &options[:if])
            unless_condition = create_unique_method(:condition,
                &options[:unless])
            consume_term = (options[:consume] != false)
            inner_rule = create_unique_method(:rule, &block)
            rule do |term|
                return if (if_condition and (not send(if_condition, term)))
                return if (unless_condition and send(unless_condition, term))
                catch(:skip) do
                    send(inner_rule, term)
                    term.consume! if consume_term
                end
            end
        end

        def self.create_unique_method(group, name = nil, &block)
            return unless block_given?
            hash = block.hash.to_s(16)
            method_name = "_#{group}"
            method_name << "_#{name}" if name
            method_name << "_#{hash}#{Time.now.to_i}#{Time.now.usec}"
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
            @stack = []
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

        def merge(predicate)
            @stack.push(@builder)
            builder = MergingBuilder.new(scope.clear, monadic_methods)
            @builder = builder
            yield
            @builder = @stack.pop
            builder.merge(predicate)
        end

        def any_of(&block)
            predicate = (@term and @term.negated?) ? :and : :or
            query = merge(predicate, &block)
            @builder.push(query)
            query
        end

        def all_of(&block)
            predicate = (@term and @term.negated?) ? :or : :and
            query = merge(predicate, &block)
            @builder.push(query)
            query
        end

        def compile(root)
            merge(root.predicate) do
                root.each do |node|
                    next(@builder.push(compile(node))) if node.group?
                    apply_rules(rules, node)
                end
            end
        end

        def apply_rules(rules, node)
            @term = ConsumableTerm.new(node)
            rules.inject([]) do |result, rule|
                return(result) if @term.consumed?
                send(rule, @term)
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
