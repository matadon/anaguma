require "spec_helper"
require "active_record"
require "anaguma/active_record/searcher"

describe Anaguma::ActiveRecord::Searcher do
    Badger = ActiveRecordTesting::Badger

    describe '#search' do
        before(:all) do
            ActiveRecordTesting.setup
            Badger.create!(name:'billy', age: 12, nickname: 'billy',
                iq: 12, eq: 12)
            Badger.create!(name:'bob', age: 35, nickname:'bobby',
                iq: 50, eq: 12)
            Badger.create!(name:'bob', age: 16, nickname: 'bubba',
                iq: 12, eq: 50)
            Badger.create!(name:'bubba', age: 25, nickname: 'lunchbox',
                iq: 50, eq: 50)
        end

        let(:searcher) { ActiveRecordTesting::BadgerSearcher.new(Badger) }

        context 'simple matching' do
            it { searches('name:billy') { |b| b['name'] == 'billy' } }
            it { searches('age>12') { |b| b['age'] > 12 } }
            it { searches('age<35') { |b| b['age'] < 35 } }
            it { searches('age<=12') { |b| b['age'] <= 12 } }
            it { searches('age>=35') { |b| b['age'] >= 35 } }
            it { searches('name~bob') { |b| b['name'] == 'bob' } }
        end

        context 'negated matching' do
            it { searches('!name:billy') { |b| b['name'] != 'billy' } }
            it { searches('!age>12') { |b| b['age'] <= 12 } }
            it { searches('!age<35') { |b| b['age'] >= 35 } }
            it { searches('!age<=12') { |b| b['age'] > 12 } }
            it { searches('!age>=35') { |b| b['age'] < 35 } }
            it { searches('!name~bob') { |b| b['name'] != 'bob' } }
        end

        context 'multiple conditions' do
            it { searches('age > 16 name:bob') { |b| 
                b['age'] > 16 && b['name'] == 'bob' } }
            it { searches('age:16 OR name:billy') { |b| 
                b['age'] == 16 || b['name'] == 'billy' } }
        end

        context 'matching on virtual fields' do
            it { searches('called:bubba') { |b| 
                b['name'] == 'bubba' || b['nickname'] == 'bubba' } }
            it { searches('!called:bubba') { |b|
                b['name'] != 'bubba' && b['nickname'] != 'bubba' } }
            it { searches('smartness>30') { |b|
                b['iq'] > 30 && b['eq'] > 30 } }
            it { searches('!smartness>30') { |b|
                b['iq'] <= 30 || b['eq'] <= 30 } }
        end

        context 'implied fields' do
            it { searches('50') { |b|
                b['age'] == 50 || b['iq'] == 50 || b['eq'] == 50 } }
        end
    end
end
