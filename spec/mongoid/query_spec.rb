require "spec_helper"
require "anaguma/mongoid/query"

MongoidTesting.test(self, Anaguma::Mongoid::Query) do
    def new_query
        Anaguma::Mongoid::Query.new(MongoidTesting::User.all)
    end

    let(:query) { new_query }

    subject { new_query }

    context "#where" do
        def where(*conditions, &block)
            result = query.where(*conditions)

            expect(result.tuples).to be_a(Array)
            expect(result.tuples).to be_all { |r|
                r.instance_of?(Moped::BSON::Document) }

            expect(result.instances).to be_a(Array)
            expect(result.instances).to be_all { |r|
                r.instance_of?(MongoidTesting::User) }

            expect(result.tuples.count).to eq(result.instances.count)

            expect(result.tuples.each_with_index).to be_all do |tuple, index|
                instance = result.instances[index]
                tuples.all? { |k, v| instance.send(k).should == v }
            end

            expect(result.instances).to be_all(&block) if block_given?
            expect(result).to_not be_empty if block_given?

            result
        end

        it_behaves_like "a monad"

        it("equals") { where(age: 50) { |i| i.age == 50 } }

        it("greater") { where(age: { "$gt" => 50 }) { |i| i.age > 50 } }

        it("less") { where(age: { "$lt" => 50 }) { |i| i.age < 50 } }

        it("greater than or equal to") {
            where(age: { "$gte" => 50 }) { |i| i.age >= 50 } }

        it("less than or equal to") {
            where(age: { "$lte" => 50 }) { |i| i.age <= 50 } }
    end

    context "#aggregate" do
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

    context "#compare" do
        it "term" do
            term = double(field: 'first_name', value: 'wyatt', operator: 'eq')
            result = query.compare(term)
            expect(result.count).to eq(1)
            expect(result.first.first_name).to eq('wyatt')
        end

        it "any" do
            term = double(field: 'name', value: 'wyatt', operator: 'gte',
                not?: false)
            result = query.compare(term, any: %w(first_name last_name))
            expect(result.count).to eq(2)
            expect(result).to be_any { |r| r.first_name == 'wyatt' }
            expect(result).to be_any { |r| r.last_name == 'young' }
        end

        it "not any" do
            term = double(field: 'name', value: 'wyatt', operator: 'ne',
                not?: true)
            result = query.compare(term, any: %w(first_name last_name))
            expect(result.count).to eq(49)
        end

        it "all" do
            term = double(field: 'name', value: 'wyatt', operator: 'eq',
                not?: false)
            result = query.compare(term, all: %w(first_name last_name))
            expect(result.count).to eq(0)
        end

        it "not all" do
            term = double(field: 'name', value: 'wyatt', operator: 'ne',
                not?: true)
            result = query.compare(term, all: %w(first_name last_name))
            expect(result.count).to eq(50)
        end
    end

    context "#merge" do
        it ":and" do
            first = new_query.where(build: "athletic")
            second = new_query.where(age: { "$gt" => 18 })
            third = new_query.where(gender: "male")
            result = first.merge(:and, second, third)
            result.count.should == 1
            result.first.email.should == "noah.roberts@irow.com"
        end

        it ":or" do
            first = new_query.where(email: "mia.jackson@irow.com")
            second = new_query.where(weight: { "$gt" => 213 })
            third = new_query.where(first_name: "ethan")
            result = first.merge(:or, second, third)
            expect(result.count).to eq(4)
            expect(result.map(&:email).sort).to eq(%w(daniel.king@najaf.cc
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
