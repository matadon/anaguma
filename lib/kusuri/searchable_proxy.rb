#
# FIXME: We need to generate a model-specific subclass of the Compiler to
# avoid polluting the global Compiler class with model-specific matches, but
# without a name, the backtrace is confusing...
#
module Kusuri
    class ProxyWithoutTargetError
    end
            
    class SearchableProxy
        def initialize(model, compiler)
            @model = model
            use(compiler)
        end

        def use(compiler)
            @compiler = compiler
            self
        end

        def method_missing(name, *args, &block)
            raise(ProxyWithoutTargetError) unless @compiler
            @compiler.send(name, *args, &block)
        end
    end
end
