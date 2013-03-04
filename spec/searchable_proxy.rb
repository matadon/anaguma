require "spec_helper"
require "anaguma/searchable_proxy"

describe Anaguma::SearchableProxy do
    let(:compiler) { Class.new }

    let(:model) { Class.new }

    let(:proxy) { Anaguma::SearchableProxy.new(model, compiler) }

    it "#new delegates" do
        compiler.should_receive(:ping)
        proxy = Anaguma::SearchableProxy.new(model, compiler)
        proxy.ping
    end

    it "#use delegates" do
        replacement = Class.new
        replacement.should_receive(:ping)
        compiler.should_not_receive(:ping)
        proxy.use(replacement)
        proxy.ping
    end
end
