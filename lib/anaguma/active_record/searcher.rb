require 'anaguma/compiler'
require 'anaguma/active_record/query'

module Anaguma
  module ActiveRecord
    class Searcher < Anaguma::Compiler
      query_class Anaguma::ActiveRecord::Query
      query_methods :select, :limit, :offset, :group, :having, :where, :compare
    end
  end
end
