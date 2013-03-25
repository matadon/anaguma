require "spec_helper"
require "anaguma/consumable_term"

describe Anaguma::ConsumableTerm do
    let(:term) { double("Term") }

    let(:consumable_term) { Anaguma::ConsumableTerm.new(term) }

    context "delegates to a term" do
        methods_delegated_to_term = %w(field operator value quoting negated?
            plaintext)

        methods_delegated_to_term.each do |method|
            it "##{method}" do
                term.should_receive(method)
                consumable_term.send(method)
            end
        end
    end

    it { expect(consumable_term).to_not be_consumed }

    it { expect(consumable_term.consume!).to be_consumed }

    it { expect(consumable_term.nom!).to be_consumed }
end
