require 'kusuri/compiler'
require 'kusuri/mongoid/query'

module Kusuri
    module Mongoid
        class Compiler < Kusuri::Compiler
            delegate :where, :compare, to: :builder

            # def self.configure_for_class(base)
            #     @model = base
            # end
        end
    end
end
