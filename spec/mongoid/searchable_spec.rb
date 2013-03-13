require "spec_helper"
require 'anaguma/mongoid/searchable'

MongoidTesting.test(self, Anaguma::Mongoid::Searchable) do
    # Subclass the model because we need to test class methods and
    # class-level operation changes.
    let(:model) { Class.new(MongoidTesting::User) }

    it "only works with Mongoid::Document" do
        expect(-> { Class.new.send(:include, Anaguma::Mongoid::Searchable) }) \
            .to raise_error(NotImplementedError)
    end

    it "adds #searchable" do
        model.should_not respond_to(:searchable)
        model.send(:include, Anaguma::Mongoid::Searchable)
        model.should respond_to(:searchable)
        model.searchable.should be_a(Anaguma::SearchableProxy)
    end

    it "adds #search" do
        model.should_not respond_to(:search)
        model.send(:include, Anaguma::Mongoid::Searchable)
        model.should respond_to(:search)
        model.search("").should be_a(Anaguma::Mongoid::Query)
    end

    it "#search uses model.all as default scope" do
        model.should_not respond_to(:search)
        model.send(:include, Anaguma::Mongoid::Searchable)
        model.should respond_to(:search)
        model.search("")._criteria.should == model.all
    end
end
