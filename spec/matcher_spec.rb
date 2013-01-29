require 'spec_helper'
require 'kusuri/matcher'

describe Kusuri::Matcher do
    let(:context) { double("Compiler") }

    let(:term) { double("Term") }

    it "sortable" do
        first = Kusuri::Matcher.new(rank: 10)
        second = Kusuri::Matcher.new(rank: 100)
        third = Kusuri::Matcher.new(rank: 1000)
        [ second, third, first ].sort.should == [ first, second, third ]
    end

    context "#match?" do
        it "all by default" do
            matcher = Kusuri::Matcher.new
            expect(matcher).to be_match(context, term)
        end

        it "if block" do
            matcher = Kusuri::Matcher.new(if: Proc.new { true })
            expect(matcher).to be_match(context, term)
        end

        it "if not block" do
            matcher = Kusuri::Matcher.new(if: Proc.new { false })
            expect(matcher).to_not be_match(context, term)
        end

        it "if method" do
            context.stub(:condition).and_return(true)
            matcher = Kusuri::Matcher.new(if: :condition)
            expect(matcher).to be_match(context, term)
        end

        it "if not method" do
            context.stub(:condition).and_return(false)
            matcher = Kusuri::Matcher.new(if: :condition)
            expect(matcher).to_not be_match(context, term)
        end

        it "unless block" do
            matcher = Kusuri::Matcher.new(unless: Proc.new { false })
            expect(matcher).to be_match(context, term)
        end

        it "unless not block" do
            matcher = Kusuri::Matcher.new(unless: Proc.new { true })
            expect(matcher).to_not be_match(context, term)
        end

        it "unless method" do
            context.stub(:condition).and_return(false)
            matcher = Kusuri::Matcher.new(unless: :condition)
            expect(matcher).to be_match(context, term)
        end

        it "unless not method" do
            context.stub(:condition).and_return(true)
            matcher = Kusuri::Matcher.new(unless: :condition)
            expect(matcher).to_not be_match(context, term)
        end

        %w(field fields).each do |method|
            context("##{method}") do
                before(:each) { term.stub(:field).and_return('age') }

                it "symbol" do
                    matcher = Kusuri::Matcher.new(method => :age)
                    expect(matcher).to be_match(context, term)
                end

                it "string" do
                    matcher = Kusuri::Matcher.new(method => 'age')
                    expect(matcher).to be_match(context, term)
                end

                it "array" do
                    matcher = Kusuri::Matcher.new(method => %w(age weight))
                    expect(matcher).to be_match(context, term)
                end

                it "not match" do
                    matcher = Kusuri::Matcher.new(method => 'weight')
                    expect(matcher).to_not be_match(context, term)
                end

                it "empty" do
                    term.stub(:field).and_return(nil)
                    matcher = Kusuri::Matcher.new(method => nil)
                    expect(matcher).to be_match(context, term)
                end

                it "not empty" do
                    term.stub(:field).and_return(nil)
                    matcher = Kusuri::Matcher.new(method => 'age')
                    expect(matcher).to_not be_match(context, term)
                end
            end
        end
    end
end
