require 'kusuri/parser'
require 'kusuri/compiler'
require 'kusuri/sql/fragment'

module Kusuri
    module Sql
        class Compiler < Kusuri::Compiler
            def self.table(name)
                @table = name
            end

            def table
                self.class.instance_variable_get("@table")
            end

            def parse(query)
                fragments = compile(Parser.parse(query)) { |term, rule|
                    Fragment.new(term, &rule) }
                Fragment.reduce(fragments).from(table)
            end
        end
    end
end
