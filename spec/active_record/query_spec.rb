require "spec_helper"
require "anaguma/active_record/query"
require 'nulldb'

describe Anaguma::ActiveRecord::Query do
    before(:all) do
        ActiveRecord::Base.establish_connection(adapter: :nulldb)
    end

    let(:relation) { ActiveRecord::Relation.new(Class.new(ActiveRecord::Base),
        Arel::Table.new('test')) }

    let(:query) { Anaguma::ActiveRecord::Query.new(relation) }

    subject { query }

    it "provides access to the underlaying ActiveRecord::Relation" do
        query.relation.should == relation
    end

    describe "#select" do
        it_behaves_like "a monad", on: :select

        it "default" do
            expect(query.clause(:select)).to be_empty
        end

        it "single column" do
            expect(query.select(:id).clause(:select)).to eq(%w(id))
        end

        it "multiple invocations" do
            updated = query.select(:one).select('two')
            expect(updated.clause(:select)).to eq(%w(one two))
        end

        it "array of columns" do
            updated = query.select(%w(one two))
            expect(updated.clause(:select)).to eq(%w(one two))
        end
    end

    describe "#compare" do
      def clause(name, operator, value)
        name = Regexp.quote name.to_s
        operator = Regexp.quote operator.to_s
        value = Regexp.quote value.to_s
        quoting = /[\s\`\'\"]*/
        /#{quoting}#{name}#{quoting}#{operator}#{quoting}#{value}#{quoting}/
      end

      it_behaves_like "a monad", on: :compare

      it 'eq' do
        term = double(field: 'name', operator:'eq', value:'billy')
        where_clauses = query.compare(term).clause(:where)
        expect(where_clauses.count).to eq(1)
        expect(where_clauses.first).to match(clause('name','=','billy'))
      end

      it 'ne' do
        term = double(field: 'name', operator:'ne', value:'billy')
        where_clauses = query.compare(term).clause(:where)
        expect(where_clauses.count).to eq(1)
        expect(where_clauses.first).to match(clause('name','!=','billy'))
      end

      it 'lt' do
        term = double(field: 'age', operator:'lt', value:'1')
        where_clauses = query.compare(term).clause(:where)
        expect(where_clauses.count).to eq(1)
        expect(where_clauses.first).to match(clause('age','<',1))
      end

      it 'gt' do
        term = double(field: 'age', operator:'gt', value:'1')
        where_clauses = query.compare(term).clause(:where)
        expect(where_clauses.count).to eq(1)
        expect(where_clauses.first).to match(clause('age','>',1))
      end

      it 'lte' do
        term = double(field: 'age', operator: 'lte', value: '1')
        where_clauses = query.compare(term).clause(:where)
        expect(where_clauses.count).to eq(1)
        expect(where_clauses.first).to match(clause('age', '<=', 1))
      end

      it 'gte' do
        term = double(field: 'age', operator: 'gte', value: '1')
        where_clauses = query.compare(term).clause(:where)
        expect(where_clauses.count).to eq(1)
        expect(where_clauses.first).to match(clause('age', '>=', 1))
      end

      it 'like same as eq' do
        term = double(field: 'name', operator: 'like', value: 'billy')
        where_clauses = query.compare(term).clause(:where)
        expect(where_clauses.count).to eq(1)
        expect(where_clauses.first).to match(clause('name', '=', 'billy'))
      end

      it 'notlike same as ne' do
        term = double(field: 'name', operator: 'notlike', value: 'billy')
        where_clauses = query.compare(term).clause(:where)
        expect(where_clauses.count).to eq(1)
        expect(where_clauses.first).to match(clause('name', '!=', 'billy'))
      end

      context 'options' do
        it 'operator override' do
          term = double(field: 'name', operator: 'gte', value: 'billy')
          where_clauses = query.compare(term, operator: 'eq').clause(:where)
          expect(where_clauses.count).to eq(1)
          expect(where_clauses.first).to match(clause('name', '=', 'billy'))
        end

        it 'value override' do
          term = double(field: 'name', operator: 'eq', value: 'billy')
          where_clauses = query.compare(term, value: 'johnny').clause(:where)
          expect(where_clauses.count).to eq(1)
          expect(where_clauses.first).to match(clause('name', '=', 'johnny'))
        end

        it 'field override' do
          term = double(field: 'moo', operator: 'eq', value: 'billy')
          where_clauses = query.compare(term, field: 'name').clause(:where)
          expect(where_clauses.count).to eq(1)
          expect(where_clauses.first).to match(clause('name', '=', 'billy'))
        end

        it 'any' do
          term = double(field: 'moniker', operator: 'eq', value: 'billy',
            not?: false)
          where_clauses = query.compare(term, any: %w(name surname)) \
            .clause(:where)
          left = clause('name', '=', 'billy')
          right = clause('surname', '=', 'billy')
          expect(where_clauses.first).to match( /\(#{left}\) OR \(#{right}\)/ )
        end

        it 'all' do
          term = double(field: 'moniker', operator: 'eq', value: 'billy',
            not?: false)
          where_clauses = query.compare(term, all:%w(name surname)) \
            .clause(:where)
          left = clause('name', '=', 'billy')
          right = clause('surname', '=', 'billy')
          expect(where_clauses.first).to match( /\(#{left}\) AND \(#{right}\)/ )
        end

        it 'not any' do
          term = double(field: 'moniker', operator: 'ne', value: 'billy',
            not?: true)
          where_clauses = query.compare(term, any: %w(name surname)) \
            .clause(:where)
          left = clause('name', '!=', 'billy')
          right = clause('surname', '!=', 'billy')
          expect(where_clauses.first).to match( /\(#{left}\) AND \(#{right}\)/ )
        end

        it 'not all' do
          term = double(field: 'moniker', operator: 'ne', value: 'billy',
            not?: true)
          where_clauses = query.compare(term, all: %w(name surname)) \
            .clause(:where)
          left = clause('name', '!=', 'billy')
          right = clause('surname', '!=', 'billy')
          expect(where_clauses.first).to match( /\(#{left}\) OR \(#{right}\)/ )
        end
      end
    end

    describe "#from" do
        it_behaves_like "a monad", on: :from

        it "default" do
            expect(query.clause(:from)).to be_nil
        end

        it "single table" do
            expect(query.from(:monkeys).clause(:from)).to eq("monkeys")
        end

        it "multiple invocations" do
            updated = query.from(:one).from('two')
            expect(updated.clause(:from)).to eq("two")
        end
    end

    describe "#joins" do
        it_behaves_like "a monad", on: :from

        it "default" do
            expect(query.clause(:joins)).to be_empty
        end

        it "single column" do
            expect(query.joins("alpha").clause(:joins)).to eq(%w(alpha))
        end

        it "multiple invocations" do
            updated = query.joins('alpha').joins('beta')
            expect(updated.clause(:joins)).to eq(%w(alpha beta))
        end

        it "array of joins" do
            updated = query.joins(%w(one two))
            expect(updated.clause(:joins)).to eq(%w(one two))
        end

        it "multiple arguments" do
            updated = query.joins(*%w(one two))
            expect(updated.clause(:joins)).to eq(%w(one two))
        end
    end

    describe "#includes" do
        it_behaves_like "a monad", on: :includes

        it "default" do
            expect(query.clause(:includes)).to be_empty
        end

        it "single column" do
            expect(query.includes("alpha").clause(:includes)).to eq(%w(alpha))
        end

        it "multiple invocations" do
            updated = query.includes('alpha').includes('beta')
            expect(updated.clause(:includes)).to eq(%w(alpha beta))
        end

        it "array of includes" do
            updated = query.includes(%w(one two))
            expect(updated.clause(:includes)).to eq(%w(one two))
        end

        it "multiple arguments" do
            updated = query.includes(*%w(one two))
            expect(updated.clause(:includes)).to eq(%w(one two))
        end
    end

    describe "#where" do
        it_behaves_like "a monad", on: :where

        it "default" do
            expect(query.clause(:where)).to be_empty
        end

        it "single condition" do
            expect(query.where("alpha").clause(:where)).to eq(["alpha"])
        end

        it "multiple invocations" do
            updated = query.where('alpha').where('beta')
            expect(updated.clause(:where)).to eq(["alpha", "beta"])
        end

        it "array of where" do
            updated = query.where("key = ?", "value")
            expect(updated.clause(:where).count).to eq(1)
            expect(updated.clause(:where).first).to \
                match(/\bkey\b.*\=.*\bvalue\b/)
        end

        it "hash of where" do
            updated = query.where(key: 'value')
            expect(updated.clause(:where).count).to eq(1)
            expect(updated.clause(:where).first).to \
                match(/\bkey\b.*\=.*\bvalue\b/)
        end
    end

    describe "#having" do
        it_behaves_like "a monad", on: :having

        it "default" do
            expect(query.clause(:having)).to be_empty
        end

        it "single condition" do
            expect(query.having("alpha").clause(:having)).to eq(["alpha"])
        end

        it "multiple invocations" do
            updated = query.having('alpha').having('beta')
            expect(updated.clause(:having)).to eq(["alpha", "beta"])
        end

        it "array of having" do
            updated = query.having("key = ?", "value")
            expect(updated.clause(:having).count).to eq(1)
            expect(updated.clause(:having).first).to \
                match(/\bkey\b.*\=.*\bvalue\b/)
        end

        it "hash of having" do
            updated = query.having(key: 'value')
            expect(updated.clause(:having).count).to eq(1)
            expect(updated.clause(:having).first).to \
                match(/\bkey\b.*\=.*\bvalue\b/)
        end
    end

    describe "#group" do
        it_behaves_like "a monad", on: :group

        it "default" do
            expect(query.clause(:group)).to be_empty
        end

        it "single column" do
            expect(query.group("id").clause(:group)).to eq(%w(id))
        end

        it "multiple invocations" do
            updated = query.group("one").group('two')
            expect(updated.clause(:group)).to eq(%w(one two))
        end

        it "array of columns" do
            updated = query.group(%w(one two))
            expect(updated.clause(:group)).to eq(%w(one two))
        end

        it "multiple arguments" do
            updated = query.group(*%w(one two))
            expect(updated.clause(:group)).to eq(%w(one two))
        end
    end

    describe "#order" do
        it_behaves_like "a monad", on: :order

        it "default" do
            expect(query.clause(:order)).to be_empty
        end

        it "single column" do
            expect(query.order("id").clause(:order)).to eq(%w(id))
        end

        it "multiple invocations" do
            updated = query.order("one").order('two')
            expect(updated.clause(:order)).to eq(%w(one two))
        end

        it "array of columns" do
            updated = query.order(%w(one two))
            expect(updated.clause(:order)).to eq(%w(one two))
        end

        it "multiple arguments" do
            updated = query.order(*%w(one two))
            expect(updated.clause(:order)).to eq(%w(one two))
        end
    end

    describe "#reorder" do
        it_behaves_like "a monad", on: :reorder

        it "default" do
            expect(query.clause(:order)).to be_empty
        end

        it "works without an initial order" do
            expect(query.reorder("id").clause(:order)).to eq(%w(id))
        end

        it "replaces the order" do
            updated = query.order("one").reorder('two')
            expect(updated.clause(:order)).to eq(%w(two))
        end

        it "array of columns" do
            updated = query.order('one').reorder(%w(one two))
            expect(updated.clause(:order)).to eq(%w(one two))
        end

        it "multiple arguments" do
            updated = query.order('one').reorder(*%w(one two))
            expect(updated.clause(:order)).to eq(%w(one two))
        end
    end

    describe "#limit" do
        it_behaves_like "a monad", on: :limit

        it "default" do
            expect(query.clause(:limit)).to be_nil
        end

        it "limits the number of results" do
            expect(query.limit(1).clause(:limit)).to eq(1)
        end

        it "unlimits the number of results" do
            expect(query.limit(1).limit(nil).clause(:limit)).to be_nil
        end

        it "overwrites on multiple invocations" do
            updated = query.limit(1).limit(10)
            expect(updated.clause(:limit)).to eq(10)
        end
    end

    describe "#offset" do
        it_behaves_like "a monad", on: :offset

        it "default" do
            expect(query.clause(:offset)).to be_nil
        end

        it "offsets the number of results" do
            expect(query.offset(1).clause(:offset)).to eq(1)
        end

        it "unoffsets the number of results" do
            expect(query.offset(1).offset(nil).clause(:offset)).to be_nil
        end

        it "overwrites on multiple invocations" do
            updated = query.offset(1).offset(10)
            expect(updated.clause(:offset)).to eq(10)
        end
    end

    it "#clause requires a valid sql clause" do
        expect { query.clause(:santa) }.to raise_error(NoMethodError)
    end

    it "#to_sql returns the sql expression" do
        expect(query.to_sql).to \
            match(/^select\b.*\.\*.*\bfrom\b.*\btest\b/i)
    end

    describe "#merge" do
        context "predicate-independent clauses" do
            it "select appends and removes duplicates" do
                first = query.select(%w(one two))
                second = query.select(%w(one three))
                expect(first.merge(:or, second).clause(:select)).to \
                    eq(%w(one two three))
            end

            it "from replaces" do
                first = query.from('alpha')
                second = query.from('beta')
                expect(first.merge(:or, second).clause(:from)).to eq('beta')
            end

            it "joins appends and removes duplicates" do
                first = query.joins(%w(one two))
                second = query.joins(%w(one three))
                expect(first.merge(:or, second).clause(:joins)).to \
                    eq(%w(one two three))
            end

            it "includes appends and removes duplicates" do
                first = query.includes(%w(one two))
                second = query.includes(%w(one three))
                expect(first.merge(:or, second).clause(:includes)).to \
                    eq(%w(one two three))
            end

            it "group appends and removes duplicates" do
                first = query.group(%w(one two))
                second = query.group(%w(one three))
                expect(first.merge(:or, second).clause(:group)).to \
                    eq(%w(one two three))
            end

            it "order appends and removes duplicates" do
                first = query.order(%w(one two))
                second = query.order(%w(one three))
                expect(first.merge(:or, second).clause(:order)).to \
                    eq(%w(one two three))
            end

            it "limit replaces" do
                first = query.limit(1)
                second = query.limit(10)
                expect(first.merge(:or, second).clause(:limit)).to eq(10)
            end

            it "offset replaces" do
                first = query.offset(1)
                second = query.offset(10)
                expect(first.merge(:or, second).clause(:offset)).to eq(10)
            end
        end

        context "where" do
            it "combines with :and" do
                first = query.where('alpha')
                second = query.where('beta')
                expect(first.merge(:and, second).clause(:where)).to \
                    eq(["(alpha) AND (beta)"])
            end

            it "combines with :or" do
                first = query.where('alpha')
                second = query.where('beta')
                expect(first.merge(:or, second).clause(:where)).to \
                    eq(["(alpha) OR (beta)"])
            end

            it "preserves bound variables" do
                first = query.where('one = ?', 1)
                second = query.where('two = ?', 2)
                first.merge(:or, second).clause(:where).should == \
                    ["(one = 1) OR (two = 2)"]
            end
        end

        context "having" do
            it "combines with :and" do
                first = query.having('alpha')
                second = query.having('beta')
                expect(first.merge(:and, second).clause(:having)).to \
                    eq(["(alpha) AND (beta)"])
            end

            it "combines with :or" do
                first = query.having('alpha')
                second = query.having('beta')
                expect(first.merge(:or, second).clause(:having)).to \
                    eq(["(alpha) OR (beta)"])
            end

            it "preserves bound variables" do
                first = query.having('one = ?', 1)
                second = query.having('two = ?', 2)
                first.merge(:or, second).clause(:having).should == \
                    ["(one = 1) OR (two = 2)"]
           end
        end

        it "merges zero additional queries" do
            unmerged = query.where("one = 1")
            merged = unmerged.merge(:and)
            expect(merged == unmerged).to be_true
            expect(merged).to_not be(unmerged)
        end

        it "behaves like a monad" do
            expect(query.merge(:and)).to be_a(query.class)
            expect(query.merge(:and)).to_not be(query)
        end
    end

    context "returning results from the database" do
        Badger = ActiveRecordTesting::Badger
        before(:all) do
          ActiveRecordTesting.setup

          billy = Badger.create!(name: 'billy')
          billy.mushrooms.create!(toxicity: 0.01)
          billy.mushrooms.create!(toxicity: 1000)

          bob = Badger.create!(name: 'bob')
          bob.mushrooms.create!(toxicity: 100)

          Badger.create!(name: 'bubba')
        end

        let(:query) { Anaguma::ActiveRecord::Query.new(Badger) }

        describe "#tuples" do
            it "returns only tuples" do
                query.tuples.should be_all { |i| i.is_a?(Hash) }
            end

            it "returns selected tuples" do
                selected = query.where(name: 'bob')
                tuples = selected.tuples
                tuples.count.should == 1
                tuples.first.should be_a(Hash)
                tuples.first['name'].should == 'bob'
            end

            it "returns tuples after merging" do
                first = query.where(name: 'bob')
                second = query.where(name: 'billy')
                merged = first.merge(:or, second)
                tuples = merged.tuples
                tuples.count.should == 2
                tuples.should be_all { |i| i.is_a?(Hash) }
                tuples.map { |i| i['name'] }.sort.should == %w(billy bob)
            end

            it "returns nothing after merging" do
                first = query.where(name: 'bob')
                second = query.where(name: 'billy')
                merged = first.merge(:and, second)
                tuples = merged.tuples
                tuples.count.should == 0
            end

            it "includes joined tables" do
                first = query.where(name: 'bob')
                second = query.where(name: 'billy')
                merged = first.merge(:or, second)
                joined = merged.joins(:mushrooms).select('*')
                joined.tuples.should be_all { |tuple|
                    tuple['toxicity'].is_a?(Float) }
            end

            it "casts types" do
                result = query.where(name: 'bob')
                expect(result.tuples.first['created_at']).to be_a(Time)
            end
        end

        it "#each iterates over #tuples" do
            expect(query).to be_all { |r| r.is_a?(Hash) }
        end

        it "#to_a" do
            query.to_a.should == query.tuples
        end

        it "#count" do
            query.count.should == 3
        end

        it "#empty?" do
            query.should_not be_empty
            query.where(name: 'fred').should be_empty
        end

        describe ".new" do
            it "from model" do
                query = Anaguma::ActiveRecord::Query.new(Badger)
                query.count.should == 3
                query.should be_all { |t| t['name'] }
            end

            it "from relation" do
                relation = Badger.where(name: 'bob')
                query = Anaguma::ActiveRecord::Query.new(relation)
                query.count.should == 1
                query.should be_all { |t| t['name'] == 'bob' }
            end

            it "from query" do
                relation = Badger.where(name: 'bob')
                subquery = Anaguma::ActiveRecord::Query.new(relation)
                query = Anaguma::ActiveRecord::Query.new(subquery)
                query.count.should == 1
                query.should be_all { |t| t['name'] == 'bob' }
            end
        end
    end
end
