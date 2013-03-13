require "spec_helper"
require "anaguma/searchable_proxy"

describe Anaguma::SearchableProxy do
    let(:searcher) { Class.new }

    let(:model) { Class.new }

    let(:proxy) { Anaguma::SearchableProxy.new(model, searcher) }

    it "#new delegates" do
        searcher.should_receive(:ping)
        proxy = Anaguma::SearchableProxy.new(model, searcher)
        proxy.ping
    end

    it "#use delegates" do
        replacement = Class.new
        replacement.should_receive(:ping)
        searcher.should_not_receive(:ping)
        proxy.use(replacement)
        proxy.ping
    end
end
