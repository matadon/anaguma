require 'spec_helper'
require 'kusuri/compiler'

describe Kusuri::Compiler do
    let(:compiler) { Class.new(Kusuri::Compiler) }

    let(:instance) { compiler.new }

    context ".parser" do
        it "default" do
            instance.parser.should be_a(Kusuri::Parser::SimpleSearchParser)
        end

        it "configurable" do
            parser = Class.new
            compiler.parser(parser)
            instance.parser.should be_an_instance_of(parser)
        end

        it "configurable when instantiated" do
            parser = Class.new
            compiler.new(nil, parser).parser.should be_a(parser)
        end

        it "inherits" do
            parser = Class.new
            compiler.parser(parser)
            subclass = Class.new(compiler)
            subclass.new.parser.should be_an_instance_of(parser)
        end

        it "overrides inherited" do
            compiler.parser(Class.new)
            subclass = Class.new(compiler)
            parser = Class.new
            subclass.parser(parser)
            subclass.new.parser.should be_an_instance_of(parser)
        end
    end

    context ".base" do
        let(:query) { double("Query") }

        it "required" do
            expect(lambda { instance.base }).to raise_error(RuntimeError)
        end

        it "configurable" do
            compiler.base(query)
            query.should_receive(:target)
            instance.base.target
        end

        it "configurable when instantiated" do
            query.should_receive(:target)
            compiler.delegate(:target, to: :base)
            compiler.new(query).target
        end

        it "inherits" do
            compiler.base(query)
            subclass = Class.new(compiler)
            query.should_receive(:target)
            subclass.new.base.target
        end
    end

    context ".rule" do
        it "define" do
            compiler.rule(:generic) { 42 }
            instance.call(:generic).should == 42
        end

        it "redefines" do
            compiler.rule(:generic) { 42 }
            expect(lambda { compiler.rule(:generic) { 42 } }).to \
                raise_error(ArgumentError)
        end

        it "inherits" do
            compiler.rule(:generic) { 42 }
            subclass = Class.new(compiler)
            subclass.new.call(:generic).should == 42
        end

        it "redefines inherited" do
            compiler.rule(:generic) { 42 }
            subclass = Class.new(compiler)
            subclass.rule(:generic) { 19 }
            subclass.new.call(:generic).should == 19
        end

        it "runs in compiler instance context" do
            compiler.rule(:generic) { self }
            instance.call(:generic).should == instance
        end

        it "early return" do
            compiler.rule(:generic) { return }
            expect(-> { instance.call(:generic) }) \
                .to_not raise_error(LocalJumpError)
        end
    end

    context "#apply_matcher_to_term" do
        let(:matcher) { double(rule: :generic) }

        let(:term) { double("Term", field: 'name', value: 'alice') }

        let(:query) { Kusuri::MockQuery.new }

        before(:each) {
            compiler.base(query).delegate(:condition, to: :builder) }

        it "returns a query" do
            compiler.rule(:generic) { condition('true') }
            result = instance.apply_matcher_to_term(matcher, term)
            result.should be_an_instance_of(Kusuri::MockQuery)
            result.should_not == query
        end

        it "builder" do
            compiler.rule(:generic) { condition(builder.class) }
            result = instance.apply_matcher_to_term(matcher, term)
            result.should == "Kusuri::Builder"
        end
        
        it "term" do
            compiler.rule(:generic) { condition(term.value) }
            result = instance.apply_matcher_to_term(matcher, term)
            result.should == "alice"
        end

        it "matcher" do
            compiler.rule(:generic) { condition(matcher.rule) }
            result = instance.apply_matcher_to_term(matcher, term)
            result.should == "generic"
        end
    end

    context "#match_and_apply_rules" do
        let(:matcher) { double(rule: :generic) }

        let(:term) { double("Term", field: 'name', value: 'alice') }

        let(:query) { Kusuri::MockQuery.new }

        before(:each) do
            compiler.base(query) \
                .delegate(:condition, to: :builder) \
                .rule(:generic) { condition(term.value) }
        end

        it "matches nothing by default" do
            result = instance.match_and_apply_rules(term)
            result.should be_a(Array)
            result.should be_empty
        end

        it "returns a set of queries" do
            compiler.match(:generic)
            result = instance.match_and_apply_rules(term)
            result.should be_a(Array)
            result.count.should == 1
            result.first.should be_a(Kusuri::MockQuery)
            result.first.should == term.value
        end

        it "inherits" do
            compiler.match(:generic)

            subclass = Class.new(compiler)

            result = subclass.new.match_and_apply_rules(term)
            result.should be_a(Array)
            result.count.should == 1
            result.first.should be_a(Kusuri::MockQuery)
            result.first.should == term.value
        end

        it "redefines inherited" do
            compiler.match(:generic)

            subclass = Class.new(compiler)
            subclass.match(:generic)

            result = subclass.new.match_and_apply_rules(term)
            result.should be_a(Array)
            result.count.should == 2
        end

        it "if-condition uses compiler instance context" do
            compiler.match(:generic) { term.value == 'alice' }
            result = instance.match_and_apply_rules(term)
            result.first.should == term.value
        end

        it "if-condition early return" do
            compiler.match(:generic) { return }
            expect(-> { instance.match_and_apply_rules(term) }) \
                .to_not raise_error(LocalJumpError)
        end

        it "unless-condition uses compiler instance context" do
            compiler.match(:generic, unless: Proc.new { term.value == 'bob' })
            result = instance.match_and_apply_rules(term)
            result.first.should == term.value
        end

        it "unless-condition early return" do
            compiler.match(:generic, unless: -> { return })
            expect(-> { instance.match_and_apply_rules(term) }) \
                .to_not raise_error(LocalJumpError)
        end

        it "matches multiple times" do
            target = double
            target.should_receive(:ping).twice
            compiler.rule(:ping) { target.ping }
            compiler.match(:ping)
            compiler.match(:ping)
            instance.match_and_apply_rules(term)
        end

        it "matches in order" do
            target = double
            target.should_receive(:first).ordered
            target.should_receive(:second).ordered
            target.should_receive(:third).ordered

            subclass = Class.new(compiler)
            compiler.rule(:first) { target.first }
            subclass.rule(:second) { target.second }
            subclass.rule(:third) { target.third }
            
            compiler.match(:first)
            subclass.match(:second)
            subclass.match(:third)
            subclass.new.match_and_apply_rules(term)
        end

        it "orders matchers by rank" do
            target = double
            target.should_receive(:third).ordered
            target.should_receive(:second).ordered
            target.should_receive(:first).ordered

            subclass = Class.new(compiler)
            compiler.rule(:first) { target.first }
            subclass.rule(:second) { target.second }
            subclass.rule(:third) { target.third }
            
            compiler.match(:first, rank: 1000)
            subclass.match(:second, rank: 100)
            subclass.match(:third, rank: 10)
            subclass.new.match_and_apply_rules(term)
        end

        it "rejects terms" do
            target = double
            target.should_not_receive(:ping)
            compiler.rule(:firewall) { term.reject! }
            compiler.rule(:ping) { target.ping }
            compiler.match(:firewall)
            compiler.match(:ping)
            instance.match_and_apply_rules(term)
        end

        context "#filter" do
            it "if false" do
                target = double
                target.should_not_receive(:ping)
                compiler.rule(:ping) { target.ping }
                compiler.filter { false }
                compiler.match(:ping)
                instance.match_and_apply_rules(term)
            end

            it "if true" do
                target = double
                target.should_receive(:ping)
                compiler.rule(:ping) { target.ping }
                compiler.filter { true }
                compiler.match(:ping)
                instance.match_and_apply_rules(term)
            end
        end

        context "#permit" do
            it "unmatched field" do
                target = double
                target.should_not_receive(:ping)
                compiler.rule(:ping) { target.ping }
                compiler.permit(:email)
                compiler.match(:ping)
                instance.match_and_apply_rules(term)
            end

            it "matched field" do
                target = double
                target.should_receive(:ping)
                compiler.rule(:ping) { target.ping }
                compiler.permit(:name)
                compiler.match(:ping)
                instance.match_and_apply_rules(term)
            end
        end
    end

    context "#parse" do
        let(:compiler) do
            Class.new(Kusuri::Compiler) do
                base(Kusuri::MockQuery.new)
                delegate(:condition, to: :builder)
            end
        end

        it "match nothing by default" do
            result = instance.parse("name: alice")
            result.should be_a(Kusuri::MockQuery)
            result.to_s.should == ""
        end

        it "match everything" do
            compiler.match(:action)
            compiler.rule(:action) { condition(term) }
            result = instance.parse("name: alice")
            result.to_s.should == "name:eq:alice"
        end

        it "or-group" do
            compiler.match(:action)
            compiler.rule(:action) { condition(term) }
            result = instance.parse("name: alice or name: bob")
            result.to_s.should == "(or name:eq:alice name:eq:bob)"
        end

        it "and-group" do
            compiler.match(:action)
            compiler.rule(:action) { condition(term) }
            result = instance.parse("name > a name < j")
            result.to_s.should == "(and name:gt:a name:lt:j)"
        end
    end
end
