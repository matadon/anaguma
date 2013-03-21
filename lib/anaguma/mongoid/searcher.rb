require 'anaguma/searcher'
require 'anaguma/mongoid/query'

module Anaguma
    module Mongoid
        class Searcher < Anaguma::Searcher
            query_class Anaguma::Mongoid::Query
        end
    end
end
