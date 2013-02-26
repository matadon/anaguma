require 'kusuri/compiler'
require 'kusuri/mongoid/query'

module Kusuri
    module Mongoid
        class Compiler < Kusuri::Compiler
            query_class Kusuri::Mongoid::Query

            query_methods :where, :compare
        end
    end
end
