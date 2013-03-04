require "spec_helper"
require "anaguma/matched_term"

describe Anaguma::MatchedTerm do
    let(:term) { double("Term") }

    let(:matched_term) { Anaguma::MatchedTerm.new(term) }

    context "delegates to a term" do
        %w(operator value quoting not? plaintext).each do |method|
            it "##{method}" do
                term.should_receive(method)
                matched_term.send(method)
            end
        end
    end

    context "#alias" do
        it "not aliased" do
            term.should_receive(:field).and_return('name')
            expect(matched_term.field).to eq('name')
        end

        it "aliased" do
            term.should_not_receive(:field)
            matched_term.alias('moniker')
            expect(matched_term.field).to eq('moniker')
        end

        it "returns a string" do
            matched_term.alias(:moniker)
            expect(matched_term.field).to eq('moniker')
        end

        it "chains" do
            expect(matched_term.alias(:moniker)).to be(matched_term)
        end
    end

    context "reject" do
        it { expect(matched_term).to_not be_rejected }
        it { expect(matched_term.reject!).to be_rejected }
    end
end
