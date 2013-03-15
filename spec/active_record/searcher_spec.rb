require "spec_helper"
require "active_record"
require "anaguma/active_record/searcher"

describe Anaguma::ActiveRecord::Searcher do
  Badger = ActiveRecordTesting::Badger

  before(:all) do
    ActiveRecordTesting.setup

    Badger.create!(name:'billy', age: 12)
    Badger.create!(name:'bob', age: 35)
  end

  let(:searcher) { ActiveRecordTesting::BadgerSearcher.new(Badger) }

  def self.it_searches(query, &block)
    it(query) do
      result = searcher.search(query)
      expect(result.instances).to be_a(Array)
      expect(result.instances).to be_all(&block) if block_given?
      expect(result).to_not be_empty if block_given?
      expect(result).to be_empty unless block_given?
    end
  end

  describe '#search' do
    it_searches('name:billy'){ |b| b.name == 'billy' }

    it_searches('age>12'){ |b| b.age > 12 }

    it_searches('age<35'){ |b| b.age < 35 }

    it_searches('age<=12'){ |b| b.age <= 12 }

    it_searches('age>=35'){ |b| b.age >= 35 }
    pending 'operators'
    pending 'multiple fields'
    pending 'implied fields'
    pending 'or'
    pending 'and'
    pending 'negation'
    pending 'grouping'
    pending 'having?'
  end
end
