require 'anaguma/builder'
require 'anaguma/matcher'
require 'anaguma/matched_term'
require 'anaguma/search_parser'

module Anaguma
    class Searcher
        attr_reader :builder, :term, :matcher

        def self.parser(parser)
            @parser = parser
            self
        end

        def self.query_class(query_class)
            @query_class = query_class
            self
        end

        def self.match(*args, &block)
            options = args.last.is_a?(Hash) ? args.pop.dup : {}
            options[:if] ||= create_non_conflicting_method(:match, &block) \
                if block_given?
            options[:rule] ||= args.first
            (@matchers ||= []).push(Matcher.new(options))
            self
        end

        def self.rule(name, &block)
            @rules ||= {}
            raise(ArgumentError, "Rule #{name} already defined.") \
                if @rules[name.to_s]
            @rules[name.to_s] = create_non_conflicting_method(:rule,
                name, &block)
            self
        end

        def self.create_non_conflicting_method(group, name = nil, &block)
            method_name = "_#{group}"
            method_name << "_#{name}" if name
            method_name << "_#{Time.now.to_i}#{Time.now.usec}"
            define_method(method_name, &block)
            method_name
        end

        def self.filter(*args, &block)
            match(*args) { |term| term.reject! unless block.call(term) }
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

        def query_class
            @_query_class ||= inherited_attribute(:query_class).compact.first \
                or raise(RuntimeError, "No query_class specified.")
        end

        def scope
            @scope.result or raise(RuntimeError, "No scope specified.")
        end

        def search(search)
            parse(search)
        end

        def parse(search)
            compile(parser.parse(search)) || query_class.new(scope)
        end

        def compile(root)
            subqueries = root.inject([]) do |memo, node|
                next(memo.push(compile(node))) if node.group?
                memo.concat(match_and_apply_rules(node))
            end
            head = subqueries.shift
            return(head) if subqueries.empty?
            head.merge(root.predicate, *subqueries)
        end

        def match_and_apply_rules(node)
            @term = MatchedTerm.new(node)
            @matchers ||= inherited_attribute(:matchers).reverse \
                .flatten.compact.sort
            @matchers.inject([]) do |memo, matcher|
                return(memo) if @term.rejected?
                next(memo) unless matcher.match?(self, @term)
                memo.push(apply_matcher_to_term(matcher, @term))
            end
        end

        def apply_matcher_to_term(matcher, term)
            @builder = Builder.new(query_class.new(scope),
                *monadic_methods)
            @term, @matcher = term, matcher
            call(matcher.rule) if matcher.rule
            @builder.result
        end

        def call(name)
            @rules ||= inherited_attribute(:rules).compact.reverse \
                .inject({}) { |memo, ruleset| memo.merge(ruleset) }
            rule = @rules[name.to_s] or raise(NotImplementedError,
                "Rule #{name} undefined for #{self.class}")
            send(rule)
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
        end
    end
end
