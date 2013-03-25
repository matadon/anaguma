require "spec_helper"
require "anaguma/mongoid/query"

MongoidTesting.test(self, Anaguma::Mongoid::Query) do
    def new_query
        Anaguma::Mongoid::Query.new(MongoidTesting::User.all)
    end

    let(:query) { new_query }

    subject { new_query }

    describe "#where" do
        def where(*conditions, &block)
            result = query.where(*conditions)
            expect(result.tuples).to be_a(Array)
            expect(result.tuples).to be_all { |r|
                r.instance_of?(Moped::BSON::Document) }
            expect(result.tuples.count).to eq(result.count)
            expect(result.tuples).to be_all(&block) if block_given?
            result
        end

        it_behaves_like "a monad", on: :where

        it("equals") { where(age: 50) { |i| i['age'] == 50 } }

        it("greater") { where(age: { "$gt" => 50 }) { |i| i['age'] > 50 } }

        it("less") { where(age: { "$lt" => 50 }) { |i| i['age'] < 50 } }

        it("greater than or equal to") {
            where(age: { "$gte" => 50 }) { |i| i['age'] >= 50 } }

        it("less than or equal to") {
            where(age: { "$lte" => 50 }) { |i| i['age'] <= 50 } }
    end

    describe "#clear" do
        it_behaves_like "a monad", on: :clear

        it "clears previously set conditions" do
            uncleared = query.where(white: 'black')
            cleared = uncleared.clear
            expect(uncleared.criteria.selector).to_not be_empty
            expect(cleared.criteria.selector).to be_empty
        end
    end

    describe "#aggregate" do
        it "count all users" do
            result = query.aggregate( \
                { "$group" => { _id: 1, count: { "$sum" => 1 } } })
            expect(result.count).to eq(1)
            expect(result.first).to eq("_id" => 1, "count" => 50)
        end

        it "average age" do
            result = query.aggregate( \
                { "$project" => { age: 1 } },
                { "$group" => { _id: 1, age: { "$avg" => '$age' } } })
            expect(result.count).to eq(1)
            expect(result.first).to eq("_id" => 1, "age" => 37.44)
        end
    end

    describe "#compare" do
        it_behaves_like "a monad", on: :compare

        before(:each) { MongoidTesting::User.create!(age: 30) }

        let(:term) { double(field: 'age', value: 30, operator: :eq) }

        it "uses field, operator, and value from term" do
            result = query.compare(term)
            expect(result).to_not be_empty
            expect(result).to be_all { |i| i['age'] == 30 }
        end

        it "overrides field" do
            MongoidTesting::User.create!(height: 30)
            result = query.compare(term, field: 'height')
            expect(result).to_not be_empty
            expect(result).to be_all { |i| i['height'] == 30 }
        end

        it "overrides operator" do
            MongoidTesting::User.create!(age: 31)
            result = query.compare(term, operator: :gt)
            expect(result).to_not be_empty
            expect(result).to be_all { |i| i['age'] > 30 }
        end

        it "overrides value" do
            MongoidTesting::User.create!(age: 969)
            result = query.compare(term, value: 969)
            expect(result).to_not be_empty
            expect(result).to be_all { |i| i['age'] == 969 }
        end

        it "works without passing a term" do
            result = query.compare(field: 'age', operator: :eq, value: 30)
            expect(result).to_not be_empty
            expect(result).to be_all { |i| i['age'] == 30 }
        end
    end

    describe "#merge" do
        it ":and" do
            first = new_query.where(build: "athletic")
            second = new_query.where(age: { "$gt" => 18 })
            third = new_query.where(gender: "male")
            result = first.merge(:and, second, third)
            result.count.should == 1
            result.first['email'].should == "noah.roberts@irow.com"
        end

        it ":or" do
            first = new_query.where(email: "mia.jackson@irow.com")
            second = new_query.where(weight: { "$gt" => 213 })
            third = new_query.where(first_name: "ethan")
            result = first.merge(:or, second, third)
            emails = result.map { |t| t['email'] }
            expect(result.count).to eq(4)
            expect(emails.sort).to eq(%w(daniel.king@najaf.cc
                ethan.brown@hotmail.com ethan.phillips@najaf.cc
                mia.jackson@irow.com))
        end
    end

    it "#limit" do
        query.limit(1).tuples.count.should == 1
        query.limit(10).tuples.count.should == 10
    end

    it "#offset" do
        query.tuples[10].should == query.offset(10).tuples.first
    end

    it "#skip" do
        query.tuples[10].should == query.skip(10).tuples.first
    end
end
