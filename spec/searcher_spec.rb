require 'spec_helper'
require 'anaguma/searcher'

describe Anaguma::Searcher do
    let(:searcher_class) do
        Class.new(Anaguma::Searcher) { query_class(Anaguma::MockQuery) }
    end

    let(:query) { String.new }

    let(:searcher) { searcher_class.new(query) }

    context "configuration" do
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

        describe ".search_in_specific_fields" do
            it "single field" do
                searcher_class.search_in_specific_fields(:name)
                result = searcher.search("name:alice age:19")
                expect(result).to eq("name:eq:alice")
            end

            it "multiple fields" do
                searcher_class.search_in_specific_fields(:name, :age)
                result = searcher.search("name:alice age:19")
                expect(result).to eq("(and name:eq:alice age:eq:19)")
            end

            it "array of multiple fields" do
                searcher_class.search_in_specific_fields(%w(name age))
                result = searcher.search("name:alice age:19")
                expect(result).to eq("(and name:eq:alice age:eq:19)")
            end

            it "if condition" do
                searcher_class.search_in_specific_fields(:name, 
                    if: lambda { |t| t.value =~ /^a/ })
                matched = searcher.search("name:alice")
                expect(matched).to eq("name:eq:alice")
                unmatched = searcher.search("name:bob")
                expect(unmatched).to eq("")
            end

            it "unless condition" do
                searcher_class.search_in_specific_fields(:name, 
                    unless: lambda { |t| t.value =~ /^a/ })
                matched = searcher.search("name:alice")
                expect(matched).to eq("")
                unmatched = searcher.search("name:bob")
                expect(unmatched).to eq("name:eq:bob")
            end

            it "consume by default" do
                searcher_class.search_in_specific_fields(:name)
                searcher_class.rule { |t| condition('red') }
                expect(searcher.search("name:alice")).to eq("name:eq:alice")
                expect(searcher.search("alice")).to eq("red")
            end

            it "doesn't consume" do
                searcher_class.search_in_specific_fields(:name, consume: false)
                searcher_class.rule { |t| condition('red') }
                expect(searcher.search("name:bob")).to \
                    eq("(and name:eq:bob red)")
                expect(searcher.search("alice")).to eq("red")
            end
        end

        describe ".search_in_any_of" do
            it "single field" do
                searcher_class.search_in_any_of(:name)
                result = searcher.search("alice")
                expect(result).to eq("name:eq:alice")
            end

            it "multiple fields" do
                searcher_class.search_in_any_of(:name, :age)
                result = searcher.search("alice")
                expect(result).to eq("(or name:eq:alice age:eq:alice)")
            end

            it "array of multiple fields" do
                searcher_class.search_in_any_of(%w(name age))
                result = searcher.search("alice")
                expect(result).to eq("(or name:eq:alice age:eq:alice)")
            end

            it "requires a field on the term" do
                searcher_class.search_in_any_of(:name, field: 'moniker')
                expect(searcher.search("alice")).to eq("")
                expect(searcher.search("name:alice")).to eq("")
                expect(searcher.search("moniker:alice")).to eq("name:eq:alice")
            end

            it "if condition" do
                searcher_class.search_in_any_of(:name, 
                    if: lambda { |t| t.value =~ /^a/ })
                matched = searcher.search("alice")
                expect(matched).to eq("name:eq:alice")
                unmatched = searcher.search("bob")
                expect(unmatched).to eq("")
            end

            it "unless condition" do
                searcher_class.search_in_any_of(:name, 
                    unless: lambda { |t| t.value =~ /^a/ })
                matched = searcher.search("alice")
                expect(matched).to eq("")
                unmatched = searcher.search("bob")
                expect(unmatched).to eq("name:eq:bob")
            end
        end

        describe ".search_in_all_of" do
            it "single field" do
                searcher_class.search_in_all_of(:name)
                result = searcher.search("alice")
                expect(result).to eq("name:eq:alice")
            end

            it "multiple fields" do
                searcher_class.search_in_all_of(:name, :age)
                result = searcher.search("alice")
                expect(result).to eq("(and name:eq:alice age:eq:alice)")
            end

            it "array of multiple fields" do
                searcher_class.search_in_all_of(%w(name age))
                result = searcher.search("alice")
                expect(result).to eq("(and name:eq:alice age:eq:alice)")
            end

            it "requires a field on the term" do
                searcher_class.search_in_all_of(:name, field: 'moniker')
                expect(searcher.search("alice")).to eq("")
                expect(searcher.search("name:alice")).to eq("")
                expect(searcher.search("moniker:alice")).to eq("name:eq:alice")
            end

            it "if condition" do
                searcher_class.search_in_all_of(:name, 
                    if: lambda { |t| t.value =~ /^a/ })
                matched = searcher.search("alice")
                expect(matched).to eq("name:eq:alice")
                unmatched = searcher.search("bob")
                expect(unmatched).to eq("")
            end

            it "unless condition" do
                searcher_class.search_in_all_of(:name, 
                    unless: lambda { |t| t.value =~ /^a/ })
                matched = searcher.search("alice")
                expect(matched).to eq("")
                unmatched = searcher.search("bob")
                expect(unmatched).to eq("name:eq:bob")
            end
        end

        describe ".search_in" do
            context "without field" do
                it "single field" do
                    searcher_class.search_in(:name)
                    result = searcher.search("alice")
                    expect(result).to eq("name:eq:alice")
                end

                it "multiple fields" do
                    searcher_class.search_in(:name, :age)
                    result = searcher.search("alice")
                    expect(result).to eq("(or name:eq:alice age:eq:alice)")
                end

                it "array of multiple fields" do
                    searcher_class.search_in(%w(name age))
                    result = searcher.search("alice")
                    expect(result).to eq("(or name:eq:alice age:eq:alice)")
                end

                it "if condition" do
                    searcher_class.search_in(:name, 
                        if: lambda { |t| t.value =~ /^a/ })
                    matched = searcher.search("alice")
                    expect(matched).to eq("name:eq:alice")
                    unmatched = searcher.search("bob")
                    expect(unmatched).to eq("")
                end

                it "unless condition" do
                    searcher_class.search_in(:name, unless: lambda { |t|
                        t.value =~ /^a/ })
                    matched = searcher.search("alice")
                    expect(matched).to eq("")
                    unmatched = searcher.search("bob")
                    expect(unmatched).to eq("name:eq:bob")
                end

                it "consume by default" do
                    searcher_class.search_in(:name)
                    searcher_class.rule { |t| condition('red') }
                    expect(searcher.search("alice")).to eq("name:eq:alice")
                end

                it "doesn't consume" do
                    searcher_class.search_in(:name, consume: false)
                    searcher_class.rule { |t| condition('red') }
                    expect(searcher.search("bob")).to \
                        eq("(and name:eq:bob red)")
                end

            end

            context "with field" do
                it "single field" do
                    searcher_class.search_in(:name)
                    result = searcher.search("name:alice age:19")
                    expect(result).to eq("name:eq:alice")
                end

                it "multiple fields" do
                    searcher_class.search_in(:name, :age)
                    result = searcher.search("name:alice age:19")
                    expect(result).to eq("(and name:eq:alice age:eq:19)")
                end

                it "array of multiple fields" do
                    searcher_class.search_in(%w(name age))
                    result = searcher.search("name:alice age:19")
                    expect(result).to eq("(and name:eq:alice age:eq:19)")
                end

                it "if condition" do
                    searcher_class.search_in(:name, 
                        if: lambda { |t| t.value =~ /^a/ })
                    matched = searcher.search("name:alice")
                    expect(matched).to eq("name:eq:alice")
                    unmatched = searcher.search("name:bob")
                    expect(unmatched).to eq("")
                end

                it "unless condition" do
                    searcher_class.search_in(:name, 
                        unless: lambda { |t| t.value =~ /^a/ })
                    matched = searcher.search("name:alice")
                    expect(matched).to eq("")
                    unmatched = searcher.search("name:bob")
                    expect(unmatched).to eq("name:eq:bob")
                end

                it "consume by default" do
                    searcher_class.search_in(:name)
                    searcher_class.rule { |t| condition('red') }
                    expect(searcher.search("alice")).to \
                        eq("name:eq:alice")
                end

                it "doesn't consume" do
                    searcher_class.search_in(:name, consume: false)
                    searcher_class.rule { |t| condition('red') }
                    expect(searcher.search("name:bob")).to \
                        eq("(and name:eq:bob red)")
                end
            end
        end

        # # Everything below should also take if: and unless: as options.

        # # If no field is specified, search in this field set by default.
        # searchable.search_in_any_of %w(first_name last_name address)
        
        # # Do both of the above.
        # searchable.search_in %w(first_name last_name
        #     email address license gender build height weight eyes age
        #     birthday)

        # # If a field is specified, search in any_of multiple fields.
        # searchable.search_in_any_of %w(first_name last_name), field: 'name'
    end
 
    describe "#scope" do
        it "configured by #new" do
            expect(searcher_class.new("a").scope).to eq("a")
        end

        it "modifiable" do
            expect(searcher_class.new("a").condition("b").scope).to eq("a b")
        end
    end

    describe "#any_of" do
        it "handles term negation" do
            searcher_class.rule { |term|
                any_of { condition "a" ; condition "b" } }
            expect(searcher.search("not thing").to_s).to eq("(and a b)")
        end

        it "merges using :or" do
            searcher_class.rule { |term|
                any_of { condition "a" ; condition "b" } }
            expect(searcher.search("something").to_s).to eq("(or a b)")
        end

        it "chains" do
            searcher_class.rule { |term|
                any_of { condition("a").condition("b" )} }
            expect(searcher.search("something").to_s).to eq("(or a b)")
        end

        it "nests" do
            searcher_class.rule do |term|
                any_of do
                    condition "a"
                    condition "b"
                    any_of do
                        condition "c"
                        condition "d"
                    end
                end
            end
            expect(searcher.search("something").to_s).to \
                eq("(or a b (or c d))")
        end
    end

    describe "#all_of" do
        it "handles term negation" do
            searcher_class.rule { |term|
                all_of { condition "a" ; condition "b" } }
            expect(searcher.search("not thing").to_s).to eq("(or a b)")
        end

        it "merges using :and" do
            searcher_class.rule { |term|
                all_of { condition "a" ; condition "b" } }
            expect(searcher.search("something").to_s).to eq("(and a b)")
        end

        it "chains" do
            searcher_class.rule { |term|
                all_of { condition("a").condition("b" )} }
            expect(searcher.search("something").to_s).to eq("(and a b)")
        end

        it "nests" do
            searcher_class.rule do |term|
                all_of do
                    condition "a"
                    condition "b"
                    all_of do
                        condition "c"
                        condition "d"
                    end
                end
            end
            expect(searcher.search("something").to_s).to \
                eq("(and a b (and c d))")
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
