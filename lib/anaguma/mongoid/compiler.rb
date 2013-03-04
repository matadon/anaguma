require 'anaguma/compiler'
require 'anaguma/mongoid/query'

module Anaguma
    module Mongoid
        class Compiler < Anaguma::Compiler
            query_class Anaguma::Mongoid::Query

            query_methods :where, :compare
        end
    end
end
