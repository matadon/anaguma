# encoding: utf-8
require 'spec_helper'
require 'kusuri/search_parser'

describe Kusuri::Search do
    let(:parser) { Kusuri::SearchParser.new }

    context ".parse" do
        context "group structure" do
            it "#group?" do
                expect(parser.parse("")).to be_group
            end

            it "#predicate and" do
                expect(parser.parse("").predicate).to eq(:and)
            end

            it "#predicate or" do
                expect(parser.parse("a or b").predicate).to eq(:or)
            end

            it "#each" do
                terms = parser.parse("a b")
                expect(terms).to be_any { |n| n.is_a?(Kusuri::Search::Term) }
                groups = parser.parse("a and b or c")
                expect(groups).to be_any { |n| n.is_a?(Kusuri::Search::Group) }
            end

            it "#to_s" do
                result = parser.parse("a or b").to_s
                expect(result).to eq("(or :eq:a :eq:b)")
            end
        end

        context "term structure" do
            def first_term(query)
                parser.parse(query).find { |t| t.is_a?(Kusuri::Search::Term) }
            end

            it "#group?" do
                expect(first_term("a")).to_not be_group
            end

            context "#field" do
                it { expect(first_term("a").field).to eq(nil) }
                it { expect(first_term("a:a").field).to eq('a') }
                it { expect(first_term("_:a").field).to eq('_') }
                it { expect(first_term("-:a").field).to eq('-') }
                it { expect(first_term("aA:a").field).to eq('aA') }
            end

            context "#operator" do
                it { expect(first_term("a:a").operator).to eq(:eq) }
                it { expect(first_term("a>a").operator).to eq(:gt) }
                it { expect(first_term("a<a").operator).to eq(:lt) }
                it { expect(first_term("a>=a").operator).to eq(:gte) }
                it { expect(first_term("a<=a").operator).to eq(:lte) }
                it { expect(first_term("a~a").operator).to eq(:like) }
            end

            context "#not?" do
                it { expect(first_term("a")).to_not be_not }
                it { expect(first_term("!a")).to be_not }
                it { expect(first_term("!a")).to be_not }
            end

            context "not #operator" do
                it { expect(first_term("!a:a").operator).to eq(:ne) }
                it { expect(first_term("!a>a").operator).to eq(:lte) }
                it { expect(first_term("!a<a").operator).to eq(:gte) }
                it { expect(first_term("!a>=a").operator).to eq(:lt) }
                it { expect(first_term("!a<=a").operator).to eq(:gt) }
                it { expect(first_term("!a~a").operator).to eq(:notlike) }
            end

            context "#value" do
                it { expect(first_term("b").value).to eq('b') }
                it { expect(first_term("'b'").value).to eq('b') }
                it { expect(first_term("\"b\"").value).to eq('b') }
                it { expect(first_term("a:'b'").value).to eq('b') }
                it { expect(first_term("a:\"b\"").value).to eq('b') }
                it { expect(first_term("a:b").value).to eq('b') }
                it { expect(first_term("a>b").value).to eq('b') }
                it { expect(first_term("a<b").value).to eq('b') }
                it { expect(first_term("a>=b").value).to eq('b') }
                it { expect(first_term("a<=b").value).to eq('b') }
                it { expect(first_term("a~b").value).to eq('b') }
                it { expect(first_term("!b").value).to eq('b') }
                it { expect(first_term("!a:b").value).to eq('b') }
                it { expect(first_term("!a>b").value).to eq('b') }
                it { expect(first_term("!a<b").value).to eq('b') }
                it { expect(first_term("!a>=b").value).to eq('b') }
                it { expect(first_term("!a<=b").value).to eq('b') }
                it { expect(first_term("!a~b").value).to eq('b') }
            end

            context "#quoting" do
                it { expect(first_term("b").quoting).to eq(:none) }
                it { expect(first_term("'b'").quoting).to eq(:single) }
                it { expect(first_term("\"b\"").quoting).to eq(:double) }
            end

            context "#text" do
                it { expect(first_term("b").text).to eq("b") }
                it { expect(first_term("a:b").text).to eq("a:b") }
                it { expect(first_term("a:'b'").text).to eq("a:'b'") }
                it { expect(first_term(" a:'b'").text).to eq("a:'b'") }
            end

            context "#to_s" do
                it { expect(first_term("b").to_s).to eq(":eq:b") }
                it { expect(first_term("a:b").to_s).to eq("a:eq:b") }
                it { expect(first_term("!a:b").to_s).to eq("!a:ne:b") }
                it { expect(first_term("!b").to_s).to eq("!:ne:b") }
            end
        end

        context "parse trees" do
            def self.parse(query, options = {})
                it("\"#{query}\"") do
                    result = nil
                    expect(lambda { result = parser.parse(query) }) \
                        .to_not raise_error
                    expect(result).to be_group
                    expect(result.to_s).to eq(options[:to])
                end
            end
            
            context "malformed" do
                parse("", to: "(and)")
                parse("and", to: "(and)")
                parse("or", to: "(or)")
                parse("and or or and or", to: "(and)")
                parse("and or or and", to: "(and)")
                parse("foo:", to: "(and)")
                parse("foo or", to: "(and :eq:foo)")
                parse("foo and", to: "(and :eq:foo)")
                parse("foo and bar:", to: "(and :eq:foo)")
                parse("foo: bar:", to: "(and foo:eq:bar:)")
                parse("foo:☃", to: "(and foo:eq:☃)")
                parse("☃:duck", to: "(and :eq:☃:duck)")
                parse(" duck", to: "(and :eq:duck)")
                parse("duck ", to: "(and :eq:duck)")
                parse(" duck ", to: "(and :eq:duck)")
                parse("'", to: "(and :eq:)")
            end

            context "booleans" do
                parse("hello or and world",
                    to: "(or :eq:hello :eq:world)")
                parse("hello or world",
                    to: "(or :eq:hello :eq:world)")
                parse("hello and world",
                    to: "(and :eq:hello :eq:world)")
                parse("hello world",
                    to: "(and :eq:hello :eq:world)")

                parse("hello and or and or world",
                    to: "(and :eq:hello :eq:world)")
                parse("hello and or or and world",
                    to: "(and :eq:hello :eq:world)")

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
                parse("is:mine", to: "(and is:eq:mine)")
                parse("is :mine", to: "(and is:eq:mine)")
                parse("is: mine", to: "(and is:eq:mine)")
                parse("is : mine", to: "(and is:eq:mine)")

                parse("age>25", to: "(and age:gt:25)")
                parse("age >25", to: "(and age:gt:25)")
                parse("age> 25", to: "(and age:gt:25)")
                parse("age > 25", to: "(and age:gt:25)")

                parse("age<25", to: "(and age:lt:25)")
                parse("age <25", to: "(and age:lt:25)")
                parse("age< 25", to: "(and age:lt:25)")
                parse("age < 25", to: "(and age:lt:25)")

                parse("age>=25", to: "(and age:gte:25)")
                parse("age >=25", to: "(and age:gte:25)")
                parse("age>= 25", to: "(and age:gte:25)")
                parse("age >= 25", to: "(and age:gte:25)")

                parse("age<=25", to: "(and age:lte:25)")
                parse("age <=25", to: "(and age:lte:25)")
                parse("age<= 25", to: "(and age:lte:25)")
                parse("age <= 25", to: "(and age:lte:25)")

                parse("age~25", to: "(and age:like:25)")
                parse("age ~25", to: "(and age:like:25)")
                parse("age~ 25", to: "(and age:like:25)")
                parse("age ~ 25", to: "(and age:like:25)")
            end
            
            context "inverse" do
                parse("!is:mine", to: "(and !is:ne:mine)")
                parse("! is:mine", to: "(and !is:ne:mine)")
                parse("not is:mine", to: "(and !is:ne:mine)")

                parse("!age>25", to: "(and !age:lte:25)")
                parse("! age>25", to: "(and !age:lte:25)")
                parse("not age>25", to: "(and !age:lte:25)")

                parse("!age<25", to: "(and !age:gte:25)")
                parse("! age<25", to: "(and !age:gte:25)")
                parse("not age<25", to: "(and !age:gte:25)")

                parse("!age>=25", to: "(and !age:lt:25)")
                parse("! age>=25", to: "(and !age:lt:25)")
                parse("not age>=25", to: "(and !age:lt:25)")

                parse("!age<=25", to: "(and !age:gt:25)")
                parse("! age<=25", to: "(and !age:gt:25)")
                parse("not age<=25", to: "(and !age:gt:25)")

                parse("!age~25", to: "(and !age:notlike:25)")
                parse("! age~25", to: "(and !age:notlike:25)")
                parse("not age~25", to: "(and !age:notlike:25)")
                parse("!age~25 or !age~35",
                    to: "(or !age:notlike:25 !age:notlike:35)")
            end

            context "quoting" do
                parse("'hello world'", to: "(and :eq:'hello world')")
                parse("' hello  world '",
                    to: "(and :eq:' hello  world ')")
                parse("'or'", to: "(and :eq:'or')")
                parse("'and'", to: "(and :eq:'and')")
                parse("'not'", to: "(and :eq:'not')")
                parse("'field:'", to: "(and :eq:'field:')")
                parse("'\\'escaped\\''", to: "(and :eq:''escaped'')")

                parse('"hello world"', to: '(and :eq:"hello world")')
                parse('" hello  world "',
                    to: '(and :eq:" hello  world ")')
                parse('"or"', to: '(and :eq:"or")')
                parse('"and"', to: '(and :eq:"and")')
                parse('"not"', to: '(and :eq:"not")')
                parse('"field:"', to: '(and :eq:"field:")')
                parse('"\\"escaped\\""', to: '(and :eq:""escaped"")')
            end

            context "field names" do
                parse("a: A", to: "(and a:eq:A)")
                parse("a-a: A", to: "(and a-a:eq:A)")
                parse("a_a: A", to: "(and a_a:eq:A)")
                parse("a0a: A", to: "(and :eq:a0a: :eq:A)")
            end
        end
    end
end
