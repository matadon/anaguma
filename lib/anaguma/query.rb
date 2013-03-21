module Anaguma
    #
    # .monadic_methods
    # .new(scope)
    # #merge
    # #tuples
    # #count
    # #each
    # #empty?
    #
    # maybe:
    # #scope
    # #compare
    #
    # name:bob or name:andy and age > 30 or age < 15
    #
    class Query
        include Enumerable

        attr_reader :scope

        def self.chain(*methods)
            mixin = methods.each_with_object(Module.new) do |method, memo|
                memo.define_method(method) do |*args, &block|
                    return(self.class.new(@scope)) \
                        if (args.empty? and not block_given?)
                    self.class.new(@scope.send(method, *args, &block))
                end
            end
            include(mixin)
            self
        end

        def initialize(scope)
            return(use_scope(scope)) unless scope.is_a?(self.class) 
            use_scope(scope.scope)
        end

        def use_scope(scope)
            @scope = scope
            self
        end

        def empty?
            count == 0
        end

        def each(&block)
            tuples.each(&block)
        end

        private

        def chain(method, *args)
        end
    end
end
