# encoding: utf-8
require 'spec_helper'
require 'kusuri/parser'

describe Kusuri::Parser do
    let(:parser) { Kusuri::Parser::SimpleSearchParser.new }

    context ".parse" do
        def parse_tree_to_string(root)
            result = root.inject([ root.predicate ]) do |memo, node|
                next(memo.push(node.to_s)) unless node.group? 
                memo.push(parse_tree_to_string(node))
            end
            "(#{result.join(" ")})"
        end

        def self.parse(query, options = {})
            it("\"#{query}\"") do
                result = nil
                expect(lambda { result = parser.parse(query) }) \
                    .to_not raise_error
                expect(result).to_not be_nil
                expect(result).to respond_to(:group?)
                expect(result).to respond_to(:predicate)
                expect(result).to respond_to(:each)
                expect(parse_tree_to_string(result)).to eq(options[:to])
            end
        end
        
        context "malformed" do
            parse("", to: "(and)")
            parse("and", to: "(and)")
            parse("or", to: "(or)")
            parse("and or or and or", to: "(and)")
            parse("and or or and", to: "(and)")
            parse("foo:", to: "(and (and))")
            parse("foo or", to: "(and (and :eq:foo :eq:or))")
            parse("foo and", to: "(and (and :eq:foo))")
            parse("foo and bar:", to: "(and (and :eq:foo))")
            parse("foo: bar:", to: "(and (and foo:eq:bar:))")
            parse("foo:☃", to: "(and (and foo:eq:☃))")
            parse("☃:duck", to: "(and (and :eq:☃:duck))")
            parse(" duck", to: "(and (and :eq:duck))")
            parse("duck ", to: "(and (and :eq:duck))")
            parse(" duck ", to: "(and (and :eq:duck))")
            parse("'", to: "(and (and :eq:))")
        end

        context "booleans" do
            parse("hello or and world",
                to: "(and (or :eq:hello :eq:world))")
            parse("hello or world",
                to: "(and (or :eq:hello :eq:world))")
            parse("hello and world",
                to: "(and (and :eq:hello :eq:world))")
            parse("hello world",
                to: "(and (and :eq:hello :eq:world))")

            parse("hello and or and or world",
                to: "(and (and :eq:hello :eq:world))")
            parse("hello and or or and world",
                to: "(and (and :eq:hello :eq:world))")

            parse("A or B and C or D",
                to: "(and (or :eq:A :eq:B) (or :eq:C :eq:D))")
            parse("A or B C or D",
                to: "(and (or :eq:A :eq:B) (or :eq:C :eq:D))")

            parse("A and B or C and D",
                to: "(and (and :eq:A) (or :eq:B :eq:C) (and :eq:D))")
            parse("A B or C D",
                to: "(and (and :eq:A) (or :eq:B :eq:C) (and :eq:D))")
            parse("A and B or and C and D",
                to: "(and (and :eq:A) (or :eq:B :eq:C) (and :eq:D))")
        end

        context "infix" do
            parse("is:mine", to: "(and (and is:eq:mine))")
            parse("is :mine", to: "(and (and is:eq:mine))")
            parse("is: mine", to: "(and (and is:eq:mine))")
            parse("is : mine", to: "(and (and is:eq:mine))")

            parse("age>25", to: "(and (and age:gt:25))")
            parse("age >25", to: "(and (and age:gt:25))")
            parse("age> 25", to: "(and (and age:gt:25))")
            parse("age > 25", to: "(and (and age:gt:25))")

            parse("age<25", to: "(and (and age:lt:25))")
            parse("age <25", to: "(and (and age:lt:25))")
            parse("age< 25", to: "(and (and age:lt:25))")
            parse("age < 25", to: "(and (and age:lt:25))")

            parse("age>=25", to: "(and (and age:gte:25))")
            parse("age >=25", to: "(and (and age:gte:25))")
            parse("age>= 25", to: "(and (and age:gte:25))")
            parse("age >= 25", to: "(and (and age:gte:25))")

            parse("age<=25", to: "(and (and age:lte:25))")
            parse("age <=25", to: "(and (and age:lte:25))")
            parse("age<= 25", to: "(and (and age:lte:25))")
            parse("age <= 25", to: "(and (and age:lte:25))")

            parse("age~25", to: "(and (and age:like:25))")
            parse("age ~25", to: "(and (and age:like:25))")
            parse("age~ 25", to: "(and (and age:like:25))")
            parse("age ~ 25", to: "(and (and age:like:25))")
        end
        
        # s/"(\(and\|or\) \(.*\))"/"(and (\1 \2))"/g
        # s/'(\(and\|or\) \(.*\))'/'(and (\1 \2))'/g

        context "inverse" do
            parse("!is:mine", to: "(and (and !is:ne:mine))")
            parse("! is:mine", to: "(and (and !is:ne:mine))")
            parse("not is:mine", to: "(and (and !is:ne:mine))")

            parse("!age>25", to: "(and (and !age:lte:25))")
            parse("! age>25", to: "(and (and !age:lte:25))")
            parse("not age>25", to: "(and (and !age:lte:25))")

            parse("!age<25", to: "(and (and !age:gte:25))")
            parse("! age<25", to: "(and (and !age:gte:25))")
            parse("not age<25", to: "(and (and !age:gte:25))")

            parse("!age>=25", to: "(and (and !age:lt:25))")
            parse("! age>=25", to: "(and (and !age:lt:25))")
            parse("not age>=25", to: "(and (and !age:lt:25))")

            parse("!age<=25", to: "(and (and !age:gt:25))")
            parse("! age<=25", to: "(and (and !age:gt:25))")
            parse("not age<=25", to: "(and (and !age:gt:25))")

            parse("!age~25", to: "(and (and !age:notlike:25))")
            parse("! age~25", to: "(and (and !age:notlike:25))")
            parse("not age~25", to: "(and (and !age:notlike:25))")
            parse("!age~25 or !age~35",
                to: "(and (or !age:notlike:25 !age:notlike:35))")
        end

        context "quoting" do
            parse("'hello world'", to: "(and (and :eq:'hello world'))")
            parse("' hello  world '", to: "(and (and :eq:' hello  world '))")
            parse("'or'", to: "(and (and :eq:'or'))")
            parse("'and'", to: "(and (and :eq:'and'))")
            parse("'not'", to: "(and (and :eq:'not'))")
            parse("'field:'", to: "(and (and :eq:'field:'))")
            parse("'\\'escaped\\''", to: "(and (and :eq:''escaped''))")

            parse('"hello world"', to: '(and (and :eq:"hello world"))')
            parse('" hello  world "', to: '(and (and :eq:" hello  world "))')
            parse('"or"', to: '(and (and :eq:"or"))')
            parse('"and"', to: '(and (and :eq:"and"))')
            parse('"not"', to: '(and (and :eq:"not"))')
            parse('"field:"', to: '(and (and :eq:"field:"))')
            parse('"\\"escaped\\""', to: '(and (and :eq:""escaped""))')
        end
    end
end
