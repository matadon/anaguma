require "spec_helper"
require "anaguma/builder"

describe Anaguma::Builder do
    let(:state) { double }

    it "binds" do
        state.should_receive(:target).and_return(state)
        builder = Anaguma::Builder.new(state, :target)
        expect(builder.target).to be(builder)
    end

    it "delegates" do
        state.should_receive(:target).and_return(42)
        builder = Anaguma::Builder.new(state)
        expect(builder.target).to eq(42)
    end

    context "#eval" do
        it "builder context" do
            state.should_receive(:target)
            builder = Anaguma::Builder.new(state)
            builder.eval { target }
        end

        it "local context" do
            state.should_receive(:target)
            builder = Anaguma::Builder.new(state)
            builder.eval { |b| b.target }
        end
    end

    it "missing method" do
        builder = Anaguma::Builder.new(Object.new)
        expect(lambda { builder.target }).to raise_error(NoMethodError)
    end
end
