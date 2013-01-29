module Kusuri
    class Matcher
        attr_reader :rule, :rank

        def initialize(options = {})
            options = symbolize_hash_keys(options)
            @rule = options.delete(:rule)
            @rank = options.delete(:rank) || 0
            @if_condition = options.delete(:if)
            @unless_condition = options.delete(:unless)
            @fields = extract_fields_from_options(options)
            return if options.empty?
            raise(ArgumentError, "Unknown options: #{options.keys.join(" ")}")
        end

        def match?(context, term)
            return(false) if (@if_condition and \
                (not run_method_or_block(context, @if_condition, term)))
            return(false) if (@unless_condition \
                and run_method_or_block(context, @unless_condition, term))
            return(false) unless (@fields.empty? \
                or @fields.include?(term.field))
            term.matchers.push(self)
            true
        end

        def <=>(other)
            other.is_a?(self.class) or raise(ArgumentError,
                "comparison of #{self.class} with #{other.class} failed")
            @rank <=> other.rank
        end

        private

        def extract_fields_from_options(options)
            value = (options.has_key?(:field) and options.delete(:field))
            value ||= (options.has_key?(:fields) and options.delete(:fields))
            [ value || [] ].flatten.map { |f| f and f.to_s }
        end

        def symbolize_hash_keys(input)
            input.inject({}) { |m, (k, v)| m[k.to_sym] = v; m }
        end

        def run_method_or_block(context, runnable, *args)
            return(context.send(runnable, *args)) \
                unless runnable.is_a?(Proc)
            context.instance_exec(*args, &runnable)
        end
    end
end
