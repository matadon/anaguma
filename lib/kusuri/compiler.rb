module Kusuri
    class Compiler
        def self.match(target, options = {})
            options = options.dup
            @rules ||= []

            if_condition = options.delete(:if)
            unless_condition = options.delete(:unless)
            fields = [ options.delete(:field), options.delete(:fields) ] \
                .flatten.compact.map { |f| f.to_s }
            options.empty? or raise(ArgumentError,
                "Unknown match options: #{options.keys.join(" ")}")
            raise(NoMethodError, "Undefined method `#{target}`") \
                unless method_defined?(target)
 
            @rules << lambda do |term|
                return if (if_condition \
                    and (not evaluate_method_or_block(if_condition, term)))
                return if (unless_condition \
                    and evaluate_method_or_block(unless_condition, term))
                return(target) if fields.empty?
                return unless fields.include?(term.field)
                target
            end
        end

        def self.default(target)
            @default = target
        end

        def self._rules
            @rules || []
        end

        def self._default
            @default
        end

        def evaluate_method_or_block(runnable, *args)
            return(runnable.call(*args)) if runnable.is_a?(Proc)
            send(runnable, *args)
        end

        def compile(*terms)
            terms.each do |term|
                target = self.class._rules.inject(nil) { |_, rule|
                    match = instance_exec(term, &rule) and break(match) }
                target ||= self.class._default
                self.send(target, term) if target
            end
            self
        end
    end
end
