require "spec_helper"
require "anaguma/maybe"

describe Anaguma::Maybe do
    let(:maybe) { Anaguma::Maybe.new("alpha") }

    it { expect(maybe.upcase).to be_an_instance_of(Anaguma::Maybe) }

    it { expect(maybe.upcase.result).to eq("ALPHA") }

    it { expect(maybe.slice(6, 0)).to be_an_instance_of(Anaguma::Maybe) }

    it { expect(maybe.slice(6, 0).result).to be_nil }
end
