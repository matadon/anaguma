require 'anaguma/searchable_proxy'
require 'anaguma/mongoid/compiler'

module Anaguma
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
                    @_searchable ||= Anaguma::SearchableProxy.new(self, 
                        Anaguma::Mongoid::Compiler)
                end

                def search(query)
                    searchable.new(self.all).search(query)
                end
            end
        end
    end
end
