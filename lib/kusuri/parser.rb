# encoding: utf-8

require 'treetop'
require 'kusuri/parser/nodes'

module Kusuri
    module Parser
        def self.parse(query)
            Thread.current[:simple_search_parser] ||= SimpleSearchParser.new
            result = Thread.current[:simple_search_parser].parse(query)
            result ? result.terms : []
        end
    end
end

grammar_file = File.join(File.dirname(__FILE__), "parser",
    "simple_search.treetop")
Treetop.load(grammar_file)
