module Kusuri
    module Delegation
        def self.included(base)
            base.send(:extend, self)
        end

        def delegate(*methods)
            options = methods.pop
            raise(ArgumentError, "Delegation needs a target.") \
                unless(options.is_a?(Hash) && options[:to])

            to = options[:to].to_s
            allow_nil = options[:allow_nil] ? 'true' : 'false'

            methods.each do |method|
                module_eval(<<-END) 
                    def #{method}(*args, &block)
                        return if (#{allow_nil} and \\
                            ((not respond_to?('#{to}') or \\
                            #{to}.nil?)))
                        return(#{to}.#{method}(*args, &block)) \\
                            if (respond_to?('#{to}') and \\
                                (not #{to}.nil?))
                        raise(TypeError,
                            "#{self}##{method} delegated to " \\
                            "#{to}.#{method}, but " \\
                            "#{to} is nil: \#{self.inspect}")
                    end
                END
            end
            self
        end
    end
end
