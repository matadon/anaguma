require 'spec_helper'
require 'anaguma/searcher'

describe Anaguma::Searcher do
    let(:searcher_class) do
        Class.new(Anaguma::Searcher) { query_class(Anaguma::MockQuery) }
    end

    let(:query) { String.new }

    let(:searcher) { searcher_class.new(query) }

    describe ".parser" do
        it "default" do
            searcher.parser.should be_a(Anaguma::SearchParser)
        end

        it "configurable" do
            parser = Class.new
            searcher_class.parser(parser)
            searcher.parser.should be_an_instance_of(parser)
        end

        it "configurable when instantiated" do
            parser = Class.new
            searcher_class.new(nil, parser).parser.should be_a(parser)
        end

        it "inherits" do
            parser = Class.new
            searcher_class.parser(parser)
            subclass = Class.new(searcher_class)
            subclass.new(query).parser.should be_an_instance_of(parser)
        end

        it "overrides inherited" do
            searcher_class.parser(Class.new)
            subclass = Class.new(searcher_class)
            parser = Class.new
            subclass.parser(parser)
            subclass.new(query).parser.should be_an_instance_of(parser)
        end
    end

    describe ".query_class" do
        let(:searcher_class) { Class.new(Anaguma::Searcher) }

        it "no default value" do
            expect(-> { searcher.query_class }) \
                .to raise_error(RuntimeError)
        end

        it "configurable" do
            searcher_class.query_class(Anaguma::MockQuery)
            expect(searcher.query_class).to eq(Anaguma::MockQuery)
        end

        it "inherits" do
            searcher_class.query_class(Anaguma::MockQuery)
            subclass = Class.new(searcher_class)
            subclass.new(query).query_class.should eq(Anaguma::MockQuery)
        end

        it "overrides inherited" do
            searcher_class.query_class(Anaguma::MockQuery)
            subclass = Class.new(searcher_class)
            query_class = Class.new(Anaguma::MockQuery)
            subclass.query_class(query_class)
            subclass.new(query).query_class.should eq(query_class)
        end
    end

    describe "#scope" do
        it "configured by #new" do
            expect(searcher_class.new("a").scope).to eq("a")
        end

        it "modifiable" do
            expect(searcher_class.new("a").condition("b").scope).to eq("a b")
        end
    end

    describe ".rule" do
        it "define" do
            searcher_class.rule { 42 }
            rule = searcher.send(:rules).first
            searcher.send(rule).should == 42
        end

        it "ordered" do
            100.times { |i| searcher_class.rule { i } }
            sequence = searcher.send(:rules).map { |r| searcher.send(r) }
            expect(sequence).to eq(100.times.to_a)
        end

        it "runs in searcher_class searcher context" do
            searcher_class.rule { self }
            rule = searcher.send(:rules).first
            searcher.send(rule).should == searcher
        end

        it "early return" do
            searcher_class.rule { return }
            rule = searcher.send(:rules).first
            expect(-> { searcher.send(rule) }).to_not \
                raise_error(LocalJumpError)
        end
    end

    describe "#search" do
        it "nil returns scope" do
            result = searcher.search(nil)
            expect(result).to be_a(Anaguma::MockQuery)
            expect(result).to eq(searcher.scope)
        end

        it "empty search string returns scope" do
            result = searcher.search("")
            expect(result).to be_a(Anaguma::MockQuery)
            expect(result).to eq(searcher.scope)
        end

        it "explodes if no ruleset is defined" do
            expect(-> { searcher.search("alice") }).to \
                raise_error(RuntimeError)
        end

        it "applies all rules in order" do
            5.times { |index| searcher_class.rule { |term|
                condition("#{index}#{term.value}") } }
            result = searcher.search("a")
            expect(result.to_s).to eq("(and 0a 1a 2a 3a 4a)")
        end

        it "applies all rules until term is consumed" do
            searcher_class.rule { |term| condition("a") and term.consume! }
            searcher_class.rule { |term| condition("b") }
            result = searcher.search("a")
            expect(result.to_s).to eq("a")
        end

        it "calls rules with terms" do
            searcher_class.rule { |term| condition(term) }
            result = searcher.search("name: alice")
            result.to_s.should == "name:eq:alice"
        end

        it "or-group" do
            searcher_class.rule(:action) { |term| condition(term) }
            result = searcher.search("name: alice or name: bob")
            result.to_s.should == "(or name:eq:alice name:eq:bob)"
        end

        it "and-group" do
            searcher_class.rule(:action) { |term| condition(term) }
            result = searcher.search("name > a name < j")
            result.to_s.should == "(and name:gt:a name:lt:j)"
        end

        describe "#filter" do
            it "if false" do
                target = double
                target.should_not_receive(:ping)
                searcher_class.filter { false }
                searcher_class.rule(:ping) { |t| target.ping }
                searcher.search("name:alice")
            end

            it "if true" do
                target = double
                target.should_receive(:ping)
                searcher_class.filter { true }
                searcher_class.rule(:ping) { |t| target.ping }
                searcher.search("name:alice")
            end
        end

        describe "#permit" do
            it "unmatched field" do
                target = double
                target.should_not_receive(:ping)
                searcher_class.permit(:email)
                searcher_class.rule(:ping) { |t| target.ping }
                searcher.search("name:alice")
            end

            it "matched field" do
                target = double
                target.should_receive(:ping)
                searcher_class.permit(:name)
                searcher_class.rule(:ping) { |t| target.ping }
                searcher.search("name:alice")
            end
        end
    end
end
