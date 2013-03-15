require "active_record"
require 'anaguma/active_record/searcher'

module ActiveRecordTesting
  class BadgerSearcher < Anaguma::ActiveRecord::Searcher
    match :generic
    rule :generic do
      compare(term)
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
                t.integer :age
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
