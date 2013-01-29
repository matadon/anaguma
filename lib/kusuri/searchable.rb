module Kusuri
    module Searchable
        class Unsupported < NotImplementedError
        end

        class ProxyWithoutTarget < NotImplementedError
        end

        class Proxy
            def initialize(base)
                @base = base
            end

            def use(compiler)
                compiler.configure_for_class(@base) \
                    if compiler.respond_to?(:configure_for_class) 
                @compiler = compiler
                self
            end

            def method_missing(name, *args, &block)
                raise(ProxyWithoutTarget) unless @compiler
                @compiler.send(name, *args, &block)
            end
        end

        def self.superclasses_for(klass)
            result = []
            while(klass)
                result << klass.to_s
                klass = klass.superclass
            end
            result
        end

        def self.included_modules_for(klass)
            klass.included_modules.map(&:to_s)
        end

        def self.extended_modules_for(klass)
            eigenclass = klass.class_eval { class << self; self end }
            included_modules_for(eigenclass)
        end

        def self.modules_for(klass)
            included_modules_for(klass) + extended_modules_for(klass)
        end

        def self.compiler_for(klass)
            contexts = superclasses_for(klass) + modules_for(klass)
            if(contexts.include?("ActiveRecord::Base"))
                require 'kusuri/active_record/compiler'
                Kusuri::ActiveRecord::Compiler
            elsif(contexts.include?("Mongoid::Document"))
                require 'kusuri/mongoid/compiler'
                Kusuri::Mongoid::Compiler
            else
                raise(Unsupported)
            end
        end

        #
        # FIXME: We need to generate a model-specific subclass of the
        # Compiler to avoid polluting the global Compiler class with
        # model-specific matches, but without a name, the backtrace is
        # confusing...
        #
        def self.included(base)
            compiler = Class.new(compiler_for(base))
            base.send(:extend, ClassMethods)
            base.searchable.use(compiler)
        end

        module ClassMethods
            def searchable
                @_searchable ||= Kusuri::Searchable::Proxy.new(self)
            end

            def search(query)
                searchable.new.search(query)
            end
        end
        
        # # only allow a set list of fields to be specified; anything not in
        # # the whitelist is passed to the default handler.
        
        # searchable.allow %w(name age birthday address)
       
        # # map a search-term-field to one or more underlaying query-fields,
        # # with possibly some knowledge of all available fields. this works
        # # on non-whitelisted fields as well, and will prevent that field
        # # from hitting the default handler.
        
        # searchable.map name: %w(first_name last_name)

        # # coerce a field to a specific type; one of: string, integer, date,
        # # timestamp, boolean

        # searchable.coerce first_name: 'string', last_name: 'string'

        # # handle search terms with no field; we treat these as plaintext,
        # # and attempt to match them against the specified fields.

        # searchable.default to: %w(name address)
        
        # # specify a join table (for sql) or embedded document field (for
        # # mongodb) that we want to proxy for certain queries

        # searchable.proxy %w(rate), via: 'rentals'
        
        # # what about fields that are the result of some operation on other
        # # fields? e.g., age could be a function of birthday

        # searchable.define age: 'TODAY - birthday'

        # # allow searching of related records via a join or embedded document
        # # left join on related table, provide an alias for any overlapping
        # # name (defaults to table-field)
        # #
        # # join or embedded document matches on field with above types;
        # # special care needs to be taken with the 'not' predicate here.
        # #
        # # for joins, we also want to know when something is in the set, or
        # # when something *isn't* in the set.
        # #
        # # on an embedded document, we should also be able to search on an
        # # aggregated field, implicitly grouped to model.id
        # #
        # # which means our result set will only select *model.id*, and we'll
        # # wrap that in something that can handle the model instantiation.
        # #
        # # returned result set should allow us to find the total count, as
        # # well as instantiate only a fraction of those items
    end
end
