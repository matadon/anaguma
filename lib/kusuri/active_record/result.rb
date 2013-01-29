require 'kusuri/delegation'

module Kusuri
    module ActiveRecord
        class Result
            include Delegation

            # FIXME: select? will select by column iff not set.
            # we also need a way of getting access to the list of selected
            # columns... hmm...
            #
            # fragments need to not self-modify; I really do want another
            # fragment with updated values... how can we do this and still
            # build a fragment via the dsl?
            #
            def initialize(fragment, model)
                @fragment, @model = fragment, model
                @fragment.from(@model.table_name)
            end

            def count
                finder.count('id')
                # @fragment.select(nil).select('count(id)')
                # binds = @fragment.sql_binds.map { |v|
                #     [ @model.columns_hash['first_name'], v ] }
                # @model.connection.select_all(@fragment.sql,
                #     nil, binds).first.values.first
            end

            def empty?
                count == 0
            end

            # FIXME: Explode if we don't have a usable id column in the
            # result.
            def instances
                ordered_ids = @model.connection \
                    .select_values(finder.select('id').to_sql)
                @model.where(id: ordered_ids).sort { |a, b| 
                    ordered_ids.index(a.id) <=> ordered_ids.index(b.id) }
                # @fragment.select(nil).select(:id)
                # binds = @fragment.sql_binds.map { |v|
                #     [ @model.columns_hash['first_name'], v ] }
                # ordered_ids = @model.connection.select_all(@fragment.sql,
                #     nil, binds).map { |r| r['id'] }
                # @model.where(id: ordered_ids).sort { |a, b| 
                #     ordered_ids.index(a.id) <=> ordered_ids.index(b.id) }
            end

            def tuples
                @model.connection.select_all(finder.to_sql)

                # @fragment.select(nil).select('*')
                # binds = @fragment.sql_binds.map { |v|
                #     [ @model.columns_hash['first_name'], v ] }
                # @model.connection.select_all(@fragment.sql, nil, binds)
            end

            private

            def finder
                where_clause = @fragment.class.parenthesize( \
                    @fragment.clause(:where))
                having_clause = @fragment.class.parenthesize( \
                    @fragment.clause(:having))
                @model.joins(@fragment.clause(:join)) \
                    .where(where_clause, *@fragment.binds(:where)) \
                    .group(@fragment.clause(:group)) \
                    .having(having_clause, *@fragment.binds(:having)) \
                    .order(@fragment.clause(:order))
            end
        end
    end
end
