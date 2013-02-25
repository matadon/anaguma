require 'date'
require "spec_helper"
require "kusuri/searchable"

MongoidTesting.test(self, "Searchable") do
    # before(:all) { MongoidTesting::User.send(:include,
    #     Kusuri::Searchable) }

    pending "implement"
    # the role of searchable is to autoconfigure itself for a mongoid model;
    # under the covers, all it does is setup permit, match, and rule for a
    # set of whitelisted attributes, and possibly rename them.
end
