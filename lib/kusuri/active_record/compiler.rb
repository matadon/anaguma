require 'kusuri/sql/compiler'
require 'kusuri/active_record/result'

module Kusuri
    module ActiveRecord
        class Compiler < Kusuri::Sql::Compiler
            def self.configure_for_class(base)
                @model = base
            end

            match :string,
                field: :name,
                aliases: %w(first_name last_name)

            rule(:first_or_last_name) do
                where(field => value) 
            end

            def search(query)
                model = self.class.instance_variable_get("@model")
                Result.new(parse(query), model)
            end
        end
    end
end
