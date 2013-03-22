require "active_record"
require 'anaguma/active_record/searcher'

module ActiveRecordTesting
    class BadgerSearcher < Anaguma::ActiveRecord::Searcher
        rule :smartness do |term|
            return unless (term.field == 'smartness')
            term.consume!
            compare(term, all: %w(iq eq))
        end

        rule :called do |term|
            return unless (term.field == 'called')
            term.consume!
            compare(term, any: %w(name nickname))
        end

        rule :generic do |term|
            next(compare(term)) if term.field
            compare(term, any: %w(name nickname age iq eq))
        end
    end

    class Badger < ActiveRecord::Base
        has_many :mushrooms
    end

    class Mushroom < ActiveRecord::Base
        belongs_to :badger
    end

    def self.setup
        ActiveRecord::Base.establish_connection(adapter: 'sqlite3',
            database: "#{File.dirname(__FILE__)}/../../tmp/test.sqlite3")

        migration = Class.new(ActiveRecord::Migration) do
            def clean_and_create_table(name, &block)
                return(execute("delete from #{name}")) \
                    if table_exists?(name)
                create_table(name, &block)
            end

            def up
                clean_and_create_table('badgers') do |t|
                    t.string :name
                    t.string :nickname
                    t.integer :age
                    t.integer :iq
                    t.integer :eq
                    t.timestamps
                end

                clean_and_create_table('mushrooms') do |t|
                    t.float :toxicity
                    t.integer :badger_id
                end
            end

            def down
                drop_table('badgers') if table_exists?('badgers')
                drop_table('mushrooms') if table_exists?('mushrooms')
            end
        end

        ActiveRecord::Migration.verbose = false
        migration.migrate(:up)
        ActiveRecord::Migration.verbose = true
    end
end
