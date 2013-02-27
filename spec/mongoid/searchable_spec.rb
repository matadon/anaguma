require "spec_helper"
require 'kusuri/mongoid/searchable'

MongoidTesting.test(self, Kusuri::Mongoid::Searchable) do
    let(:model) { Class.new(MongoidTesting::User) }

    it "only works with Mongoid::Document" do
        expect(-> { Class.new.send(:include, Kusuri::Mongoid::Searchable) }) \
            .to raise_error(NotImplementedError)
    end

    it "adds #searchable" do
        model.should_not respond_to(:searchable)
        model.send(:include, Kusuri::Mongoid::Searchable)
        model.should respond_to(:searchable)
        model.searchable.should be_a(Kusuri::SearchableProxy)
    end

    it "adds #search" do
        model.should_not respond_to(:search)
        model.send(:include, Kusuri::Mongoid::Searchable)
        model.should respond_to(:search)
        model.search("").should be_a(Kusuri::Mongoid::Query)
    end

    it "#search uses model.all as default scope" do
        model.should_not respond_to(:search)
        model.send(:include, Kusuri::Mongoid::Searchable)
        model.should respond_to(:search)
        model.search("")._criteria.should == model.all
    end
end
