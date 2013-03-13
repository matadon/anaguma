require 'spec_helper'
require 'anaguma/searcher'

describe Anaguma::Searcher do
    let(:searcher) do
        Class.new(Anaguma::Searcher) do
            query_class(Anaguma::MockQuery) 
            query_methods(:condition)
        end
    end

    let(:query) { String.new }

    let(:instance) { searcher.new(query) }

    context ".parser" do
        it "default" do
            instance.parser.should be_a(Anaguma::SearchParser)
        end

        it "configurable" do
            parser = Class.new
            searcher.parser(parser)
            instance.parser.should be_an_instance_of(parser)
        end

        it "configurable when instantiated" do
            parser = Class.new
            searcher.new(nil, parser).parser.should be_a(parser)
        end

        it "inherits" do
            parser = Class.new
            searcher.parser(parser)
            subclass = Class.new(searcher)
            subclass.new(query).parser.should be_an_instance_of(parser)
        end

        it "overrides inherited" do
            searcher.parser(Class.new)
            subclass = Class.new(searcher)
            parser = Class.new
            subclass.parser(parser)
            subclass.new(query).parser.should be_an_instance_of(parser)
        end
    end

    context ".query_class" do
        let(:searcher) { Class.new(Anaguma::Searcher).query_methods(:foo) }

        it "no default value" do
            expect(-> { instance.query_class }) \
                .to raise_error(RuntimeError)
        end

        it "configurable" do
            searcher.query_class(Anaguma::MockQuery)
            expect(instance.query_class).to eq(Anaguma::MockQuery)
        end

        it "inherits" do
            searcher.query_class(Anaguma::MockQuery)
            subclass = Class.new(searcher)
            subclass.new(query).query_class.should eq(Anaguma::MockQuery)
        end

        it "overrides inherited" do
            searcher.query_class(Anaguma::MockQuery)
            subclass = Class.new(searcher)
            query_class = Class.new(Anaguma::MockQuery)
            subclass.query_class(query_class)
            subclass.new(query).query_class.should eq(query_class)
        end
    end

    context ".query_methods" do
        let(:searcher) { Class.new(Anaguma::Searcher) \
            .query_class(Anaguma::MockQuery) }

        it "no default value" do
            expect(-> { instance.query_methods }).to raise_error(RuntimeError)
        end

        it "configurable" do
            query_methods = %w(foo bar)
            searcher.query_methods(query_methods)
            expect(instance.query_methods).to eq(query_methods)
        end

        it "inherits" do
            query_methods = %w(foo bar)
            searcher.query_methods(query_methods)
            subclass = Class.new(searcher)
            subclass.new(query).query_methods.should eq(query_methods)
        end

        it "overrides inherited" do
            searcher.query_methods(%w(foo bar))
            subclass = Class.new(searcher)
            query_methods = %w(foo bar)
            subclass.query_methods(query_methods)
            subclass.new(query).query_methods.should eq(query_methods)
        end
    end

    context "#scope" do
        it "configured by #new" do
            instance = searcher.new("foo")
            instance.condition("bar").result.should == "foo bar"
        end

        it "modifiable" do
            searcher.query_methods(:condition)
            instance.builder.should_not be_nil
            instance.builder.result.should == ""
            instance.condition("foo").result.should == "foo"
        end
    end

    context ".rule" do
        it "define" do
            searcher.rule(:generic) { 42 }
            instance.call(:generic).should == 42
        end

        it "redefines" do
            searcher.rule(:generic) { 42 }
            expect(lambda { searcher.rule(:generic) { 42 } }).to \
                raise_error(ArgumentError)
        end

        it "inherits" do
            searcher.rule(:generic) { 42 }
            subclass = Class.new(searcher)
            subclass.new(query).call(:generic).should == 42
        end

        it "redefines inherited" do
            searcher.rule(:generic) { 42 }
            subclass = Class.new(searcher)
            subclass.rule(:generic) { 19 }
            subclass.new(query).call(:generic).should == 19
        end

        it "runs in searcher instance context" do
            searcher.rule(:generic) { self }
            instance.call(:generic).should == instance
        end

        it "early return" do
            searcher.rule(:generic) { return }
            expect(-> { instance.call(:generic) }) \
                .to_not raise_error(LocalJumpError)
        end
    end

    context "#apply_matcher_to_term" do
        let(:matcher) { double(rule: :generic) }

        let(:term) { double("Term", field: 'name', value: 'alice') }

        it "returns a query" do
            searcher.rule(:generic) { condition('true') }
            result = instance.apply_matcher_to_term(matcher, term)
            result.should be_an_instance_of(Anaguma::MockQuery)
            result.should_not == query
        end

        it "builder" do
            searcher.rule(:generic) { condition(builder.class) }
            result = instance.apply_matcher_to_term(matcher, term)
            result.should == "Anaguma::Builder"
        end
        
        it "term" do
            searcher.rule(:generic) { condition(term.value) }
            result = instance.apply_matcher_to_term(matcher, term)
            result.should == "alice"
        end

        it "matcher" do
            searcher.rule(:generic) { condition(matcher.rule) }
            result = instance.apply_matcher_to_term(matcher, term)
            result.should == "generic"
        end
    end

    context "#match_and_apply_rules" do
        let(:matcher) { double(rule: :generic) }

        let(:term) { double("Term", field: 'name', value: 'alice') }

        before(:each) { searcher.rule(:generic) { condition(term.value) } }

        it "matches nothing by default" do
            result = instance.match_and_apply_rules(term)
            result.should be_a(Array)
            result.should be_empty
        end

        it "returns a set of queries" do
            searcher.match(:generic)
            result = instance.match_and_apply_rules(term)
            result.should be_a(Array)
            result.count.should == 1
            result.first.should be_a(Anaguma::MockQuery)
            result.first.should == term.value
        end

        it "inherits" do
            searcher.match(:generic)

            subclass = Class.new(searcher)

            result = subclass.new(query).match_and_apply_rules(term)
            result.should be_a(Array)
            result.count.should == 1
            result.first.should be_a(Anaguma::MockQuery)
            result.first.should == term.value
        end

        it "redefines inherited" do
            searcher.match(:generic)

            subclass = Class.new(searcher)
            subclass.match(:generic)

            result = subclass.new(query).match_and_apply_rules(term)
            result.should be_a(Array)
            result.count.should == 2
        end

        it "if-condition uses searcher instance context" do
            searcher.match(:generic) { term.value == 'alice' }
            result = instance.match_and_apply_rules(term)
            result.first.should == term.value
        end

        it "if-condition early return" do
            searcher.match(:generic) { return }
            expect(-> { instance.match_and_apply_rules(term) }) \
                .to_not raise_error(LocalJumpError)
        end

        it "unless-condition uses searcher instance context" do
            searcher.match(:generic, unless: Proc.new { term.value == 'bob' })
            result = instance.match_and_apply_rules(term)
            result.first.should == term.value
        end

        it "unless-condition early return" do
            searcher.match(:generic, unless: -> { return })
            expect(-> { instance.match_and_apply_rules(term) }) \
                .to_not raise_error(LocalJumpError)
        end

        it "matches multiple times" do
            target = double
            target.should_receive(:ping).twice
            searcher.rule(:ping) { target.ping }
            searcher.match(:ping)
            searcher.match(:ping)
            instance.match_and_apply_rules(term)
        end

        it "matches in order" do
            target = double
            target.should_receive(:first).ordered
            target.should_receive(:second).ordered
            target.should_receive(:third).ordered

            subclass = Class.new(searcher)
            searcher.rule(:first) { target.first }
            subclass.rule(:second) { target.second }
            subclass.rule(:third) { target.third }
            
            searcher.match(:first)
            subclass.match(:second)
            subclass.match(:third)
            subclass.new(query).match_and_apply_rules(term)
        end

        it "orders matchers by rank" do
            target = double
            target.should_receive(:third).ordered
            target.should_receive(:second).ordered
            target.should_receive(:first).ordered

            subclass = Class.new(searcher)
            searcher.rule(:first) { target.first }
            subclass.rule(:second) { target.second }
            subclass.rule(:third) { target.third }
            
            searcher.match(:first, rank: 1000)
            subclass.match(:second, rank: 100)
            subclass.match(:third, rank: 10)
            subclass.new(query).match_and_apply_rules(term)
        end

        it "rejects terms" do
            target = double
            target.should_not_receive(:ping)
            searcher.rule(:firewall) { term.reject! }
            searcher.rule(:ping) { target.ping }
            searcher.match(:firewall)
            searcher.match(:ping)
            instance.match_and_apply_rules(term)
        end

        context "#filter" do
            it "if false" do
                target = double
                target.should_not_receive(:ping)
                searcher.rule(:ping) { target.ping }
                searcher.filter { false }
                searcher.match(:ping)
                instance.match_and_apply_rules(term)
            end

            it "if true" do
                target = double
                target.should_receive(:ping)
                searcher.rule(:ping) { target.ping }
                searcher.filter { true }
                searcher.match(:ping)
                instance.match_and_apply_rules(term)
            end
        end

        context "#permit" do
            it "unmatched field" do
                target = double
                target.should_not_receive(:ping)
                searcher.rule(:ping) { target.ping }
                searcher.permit(:email)
                searcher.match(:ping)
                instance.match_and_apply_rules(term)
            end

            it "matched field" do
                target = double
                target.should_receive(:ping)
                searcher.rule(:ping) { target.ping }
                searcher.permit(:name)
                searcher.match(:ping)
                instance.match_and_apply_rules(term)
            end
        end
    end

    context "#parse" do
        it "match nothing by default" do
            result = instance.parse("name: alice")
            result.should be_a(Anaguma::MockQuery)
            result.to_s.should == ""
        end

        it "match everything" do
            searcher.match(:action)
            searcher.rule(:action) { condition(term) }
            result = instance.parse("name: alice")
            result.to_s.should == "name:eq:alice"
        end

        it "or-group" do
            searcher.match(:action)
            searcher.rule(:action) { condition(term) }
            result = instance.parse("name: alice or name: bob")
            result.to_s.should == "(or name:eq:alice name:eq:bob)"
        end

        it "and-group" do
            searcher.match(:action)
            searcher.rule(:action) { condition(term) }
            result = instance.parse("name > a name < j")
            result.to_s.should == "(and name:gt:a name:lt:j)"
        end
    end
end
