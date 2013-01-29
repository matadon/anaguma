require 'kusuri/delegation'

module Kusuri
    module Sql
        class Fragment
            OPERATORS = { eq: '=', gt: '>', lt: '<', lte: '<=', gte: '>=' }

            NEGATED_OPERATORS = { eq: '!=', gt: '<=', lt: '>=', lte: '>',
                gte: '<' }

            include Delegation

            attr_reader :term

            delegate :field, :operator, :value, :quoting, :or?, :not?,
                :plaintext, to: :term

            def self.reduce(fragments)
                combine_chunks(chunk_by_predicate(fragments))
            end

            def self.chunk_by_predicate(fragments)
                return([]) if fragments.empty?
                index, chunk = 0, 0
                chunks = fragments.chunk do |item|
                    behind = (index == 0) ? nil : fragments[index - 1]
                    ahead = fragments[index + 1]
                    item_matches = item.and?
                    ahead_does_not_match = (ahead and (not ahead.and?))
                    behind_does_not_match = (behind and (not behind.and?))
                    index += 1
                    chunk += 1 if (item_matches and (ahead_does_not_match \
                        or behind_does_not_match))
                    chunk
                end
                chunks.map(&:last)
            end

            def self.combine_chunks(chunks)
                chunks.inject(new) do |statement, fragments|
                    predicate = fragments.last.and? ? :and : :or

                    %w(select from join group order).each do |name|
                        clauses = fragments.inject([]) { |result, fragment|
                            result.concat(fragment.clause(name)) }
                        statement.send(name, *clauses)
                    end

                    %w(where having).each do |name|
                        clauses = fragments.map { |fragment|
                            parenthesize(fragment.clause(name)) }
                        binds = fragments.inject([]) { |result, fragment|
                            result.concat(fragment.binds(name)) }
                        next if clauses.compact.empty?
                        statement.send(name, parenthesize(clauses,
                            predicate), *binds)
                    end

                    statement
                end
            end

            def self.parenthesize(array, separator = "and")
                return if array.empty?
                return(array.first) if (array.length == 1)
                "(#{array.join(" #{separator} ")})"
            end

            def initialize(term = nil, &block)
                @term = term
                @clauses = Hash.new { |h, k| h[k] = Array.new } 
                instance_eval(&block) if block_given?
            end

            %w(select from join group order).each do |name|
                define_method(name) do |*args|
                    if(args.first.nil?)
                        @clauses[name.to_sym].clear
                    else
                        @clauses[name.to_sym].push(args).uniq!
                    end
                    self
                end
            end

            %w(where having).each do |name|
                define_method(name) do |*args|
                    @clauses[name.to_sym].push(args)
                    return(self) if args.first.is_a?(Hash)
                    placeholders = args.first.scan(/\b?\?\b?/)
                    return(self) if (placeholders.count == (args.length - 1))
                    raise(ArgumentError, "Not as many binds as placeholders.")
                end
            end

            def limit(rows)
                @limit = rows
                self
            end

            def offset(rows)
                @offset = rows
                self
            end

            def and?
                term ? @term.and? : true
            end

            def operator
                return(NEGATED_OPERATORS[@term.operator]) if not?
                OPERATORS[@term.operator]
            end

            def clause(name)
                name = name.to_sym
                return([]) if @clauses[name].empty?
                case(name)
                when :where, :having
                    combined = @clauses[name].map do |args|
                        next(args.first) unless args.first.is_a?(Hash)
                        args.first.keys.map { |k| "#{k} = ?" }
                    end
                    combined.flatten
                when :select, :from, :join, :group, :order
                    @clauses[name].flatten
                end
            end

            def binds(name)
                name = name.to_sym
                raise(NotImplementedError, "Only where and having clauses" \
                    + "allow bind variables.") unless((name == :where) \
                    or (name == :having))
                @clauses[name].inject([]) do |result, args|
                    next(result.concat(args.first.values)) \
                        if args.first.is_a?(Hash)
                    result.concat(args.slice(1, args.length))
                end
            end

            def sql
                result = [ ]
                result << "select #{clause(:select).join(', ')}" \
                    unless clause(:select).empty?
                result << "from #{clause(:from).join(', ')}" \
                    unless clause(:from).empty?
                result << clause(:join).join(' ') \
                    unless clause(:join).empty?
                result << "where #{self.class.parenthesize(clause(:where))}" \
                    unless clause(:where).empty?
                result << "group by #{clause(:group).join(', ')}" \
                    unless clause(:group).empty?
                result << "having #{self.class.parenthesize(clause(:having))}" \
                    unless clause(:having).empty?
                result << "order by #{clause(:order).join(', ')}" \
                    unless clause(:order).empty?
                result << "limit #{@limit}" if @limit
                result << "offset #{@offset}" if @offset

                index = 0
                result.join(" ").gsub(/(\b?)(\?)(\b?)/) { |m|
                    "#{m[1]}$#{index += 1}#{m[2]}" }
            end

            def sql_binds
                binds(:where) + binds(:having)
            end
        end
    end
end
