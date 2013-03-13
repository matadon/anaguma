require 'spec_helper'
require 'anaguma/matcher'

describe Anaguma::Matcher do
    let(:context) { double("Searcher") }

    let(:term) { double("Term", matchers: []) }

    it "sortable" do
        first = Anaguma::Matcher.new(rank: 10)
        second = Anaguma::Matcher.new(rank: 100)
        third = Anaguma::Matcher.new(rank: 1000)
        [ second, third, first ].sort.should == [ first, second, third ]
    end

    context "#match?" do
        it "rejects unknown options" do
            expect(-> { Anaguma::Matcher.new(tubular: 'noobtastic') }) \
                .to raise_error(ArgumentError)
        end

        it "all by default" do
            matcher = Anaguma::Matcher.new
            expect(matcher).to be_match(context, term)
        end

        it "if block" do
            matcher = Anaguma::Matcher.new(if: Proc.new { true })
            expect(matcher).to be_match(context, term)
        end

        it "if not block" do
            matcher = Anaguma::Matcher.new(if: Proc.new { false })
            expect(matcher).to_not be_match(context, term)
        end

        it "if method" do
            context.stub(:condition).and_return(true)
            matcher = Anaguma::Matcher.new(if: :condition)
            expect(matcher).to be_match(context, term)
        end

        it "if not method" do
            context.stub(:condition).and_return(false)
            matcher = Anaguma::Matcher.new(if: :condition)
            expect(matcher).to_not be_match(context, term)
        end

        it "unless block" do
            matcher = Anaguma::Matcher.new(unless: Proc.new { false })
            expect(matcher).to be_match(context, term)
        end

        it "unless not block" do
            matcher = Anaguma::Matcher.new(unless: Proc.new { true })
            expect(matcher).to_not be_match(context, term)
        end

        it "unless method" do
            context.stub(:condition).and_return(false)
            matcher = Anaguma::Matcher.new(unless: :condition)
            expect(matcher).to be_match(context, term)
        end

        it "unless not method" do
            context.stub(:condition).and_return(true)
            matcher = Anaguma::Matcher.new(unless: :condition)
            expect(matcher).to_not be_match(context, term)
        end

        %w(field fields).each do |method|
            context("##{method}") do
                before(:each) { term.stub(:field).and_return('age') }

                it "symbol" do
                    matcher = Anaguma::Matcher.new(method => :age)
                    expect(matcher).to be_match(context, term)
                end

                it "string" do
                    matcher = Anaguma::Matcher.new(method => 'age')
                    expect(matcher).to be_match(context, term)
                end

                it "array" do
                    matcher = Anaguma::Matcher.new(method => %w(age weight))
                    expect(matcher).to be_match(context, term)
                end

                it "not match" do
                    term.should_not_receive(:matchers)
                    matcher = Anaguma::Matcher.new(method => 'weight')
                    expect(matcher).to_not be_match(context, term)
                end

                it "empty" do
                    term.stub(:field).and_return(nil)
                    matcher = Anaguma::Matcher.new(method => nil)
                    expect(matcher).to be_match(context, term)
                end

                it "not empty" do
                    term.should_not_receive(:matchers)
                    term.stub(:field).and_return(nil)
                    matcher = Anaguma::Matcher.new(method => 'age')
                    expect(matcher).to_not be_match(context, term)
                end
            end
        end
    end
end
