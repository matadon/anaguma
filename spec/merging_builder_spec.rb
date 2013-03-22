require "spec_helper"
require "anaguma/merging_builder"

describe Anaguma::MergingBuilder do
    let(:query) { Anaguma::MockQuery.new }

    let(:builder) { Anaguma::MergingBuilder.new(query,
        query.class.monadic_methods) }

    describe "#merge" do
        it "returns the original scope" do
            expect(builder.merge(:or)).to eq(query)
        end

        it "or conditons" do
            builder.condition('a')
            builder.condition('b')
            expect(builder.merge(:or)).to eq("(or a b)")
        end

        it "and conditions" do
            builder.condition('a')
            builder.condition('b')
            expect(builder.merge(:and)).to eq("(and a b)")
        end

        it "#push adds a mergeable query" do
            builder.condition('a')
            builder.push(Anaguma::MockQuery.new("b"))
            expect(builder.merge(:and)).to eq("(and a b)")
        end
    end
end
