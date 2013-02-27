require 'kusuri/searchable_proxy'
require 'kusuri/mongoid/compiler'

module Kusuri
    module Mongoid
        module Searchable
            def self.included(base)
                is_mongoid = base.included_modules.any? { |m|
                    m.to_s == "Mongoid::Document" }
                is_mongoid or raise(NotImplementedError,
                    "#{self} may only be included in a Mongoid::Document")
                base.send(:extend, ClassMethods)
            end

            module ClassMethods
                def searchable
                    @_searchable ||= Kusuri::SearchableProxy.new(self, 
                        Kusuri::Mongoid::Compiler)
                end

                def search(query)
                    searchable.new(self.all).search(query)
                end
            end
        end
    end
end
