require "spec_helper"
require "active_record"
require "anaguma/active_record/searcher"

describe Anaguma::ActiveRecord::Searcher do
  Badger = ActiveRecordTesting::Badger

  before(:all) do
    ActiveRecordTesting.setup

    Badger.create!(name:'billy', age: 12, nickname:'billy',   iq: 12, eq: 12)
    Badger.create!(name:'bob',   age: 35, nickname:'bobby',   iq: 50, eq: 12)
    Badger.create!(name:'bob', age: 16, nickname: 'bubba',  iq: 12, eq: 50)
    Badger.create!(name:'bubba', age: 25, nickname:'lunchbox', iq: 50, eq: 50)
  end

  let(:searcher) { ActiveRecordTesting::BadgerSearcher.new(Badger) }

  def self.it_searches(query, &block)
    it(query) do
      result = searcher.search(query)
      expect(result.instances).to be_a(Array)
      if block_given?
        all_matches = Badger.all.select(&block).sort_by(&:id)
        returned_matches = result.instances.sort_by(&:id)
        expect(returned_matches).to eq(all_matches)
        expect(result).to_not be_empty
      else
        expect(result).to be_empty
      end
    end
  end

  describe '#search' do
    context 'simple matching' do

      it_searches('name:billy') { |b| b.name == 'billy' }

      it_searches('age>12') { |b| b.age > 12 }

      it_searches('age<35') { |b| b.age < 35 }

      it_searches('age<=12') { |b| b.age <= 12 }

      it_searches('age>=35') { |b| b.age >= 35 }

      it_searches('name~bob') { |b| b.name == 'bob' }

    end

    context 'negated matching' do

      it_searches('!name:billy') { |b| b.name != 'billy' }

      it_searches('!age>12') { |b| b.age <= 12 }

      it_searches('!age<35') { |b| b.age >= 35 }

      it_searches('!age<=12') { |b| b.age > 12 }

      it_searches('!age>=35') { |b| b.age < 35 }

      it_searches('!name~bob') { |b| b.name != 'bob' }

    end

    context 'multiple conditions' do

      it_searches('age > 16 name:bob') { |b| b.age > 16 && b.name == 'bob' }

      it_searches('age:16 OR name:billy') do |b|
        b.age == 16 || b.name == 'billy'
      end

    end

    context 'matching on virtual fields' do
      it_searches('called:bubba') do |b|
        b.name=='bubba' || b.nickname == 'bubba'
      end

      it_searches('!called:bubba') do |b|
        b.name!='bubba' && b.nickname != 'bubba'
      end

      it_searches('smartness>30') do |b|
        b.iq > 30 && b.eq > 30
      end

      it_searches('!smartness>30') do |b|
        b.iq <= 30 || b.eq <= 30
      end
    end


    context 'implied fields' do
      it_searches('50') do |b|
        b.age == 50 ||
        b.iq == 50 ||
        b.eq == 50
      end
    end
  end
end
