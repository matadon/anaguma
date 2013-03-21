require 'anaguma/searcher'
require 'anaguma/active_record/query'

module Anaguma
    module ActiveRecord
        class Searcher < Anaguma::Searcher
            query_class Anaguma::ActiveRecord::Query
        end
    end
end
