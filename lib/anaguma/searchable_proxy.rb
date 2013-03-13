#
# FIXME: We need to generate a model-specific subclass of the Searcher to
# avoid polluting the global Searcher class with model-specific matches, but
# without a name, the backtrace is confusing...
#
module Anaguma
    class ProxyWithoutTargetError
    end
            
    class SearchableProxy
        def initialize(model, searcher)
            @model = model
            use(searcher)
        end

        def use(searcher)
            @searcher = searcher
            self
        end

        def method_missing(name, *args, &block)
            raise(ProxyWithoutTargetError) unless @searcher
            @searcher.send(name, *args, &block)
        end
    end
end
