require 'kusuri/builder'
require 'kusuri/delegation'
require 'kusuri/matcher'
require 'kusuri/matched_term'
require 'kusuri/parser'

module Kusuri
    class Compiler
        include Delegation

        attr_reader :builder, :term, :matcher

        def self.parser(parser)
            @parser = parser
            self
        end

        def self.base(base)
            @base = base
            self
        end

        def self.match(*args, &block)
            options = args.last.is_a?(Hash) ? args.pop.dup : {}
            options[:if] ||= block if block_given?
            options[:rule] ||= args.first
            (@matchers ||= []).push(Matcher.new(options))
            self
        end

        def self.rule(name, &block)
            @rules ||= {}
            raise(ArgumentError, "Rule #{name} already defined.") \
                if @rules[name.to_s]
            @rules[name.to_s] = block
            self
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

        def initialize(base = nil, parser = nil)
            @base, @parser = base, parser
        end

        def query_class
            @query_class ||= base.class
        end

        def parser
            @parser ||= (inherited_attribute(:parser).compact.first \
                or Kusuri::Parser::SimpleSearchParser).new
        end

        def base
            @base ||= inherited_attribute(:base).compact.first \
                or raise(RuntimeError, "No Query base specified")
        end

        def search(search)
            parse(search)
        end

        def parse(search)
            compile(parser.parse(search)) || base
        end
 
        def compile(root)
            subqueries = root.inject([]) do |memo, node|
                next(memo.push(compile(node))) if node.group?
                memo.concat(match_and_apply_rules(node))
            end
            query_class.merge(root.predicate, *subqueries)
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
            @builder = base.class.builder(base)
            @term, @matcher = term, matcher
            call(matcher.rule) if matcher.rule
            @builder.result
        end

        def call(name)
            @rules ||= inherited_attribute(:rules).compact.reverse \
                .inject({}) { |memo, ruleset| memo.merge(ruleset) }
            rule = @rules[name.to_s] or raise(NotImplementedError, 
                "Rule #{name} undefined for #{self.class}")
            instance_eval(&rule)
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
    end
end
