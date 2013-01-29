require "spec_helper"
require "kusuri/mongoid/aggregate_query"

MongoidTesting.test(self, Kusuri::Mongoid::AggregateQuery) do
    def new_query
        Kusuri::Mongoid::AggregateQuery.new(MongoidTesting::User.all)
    end

    let(:query) { new_query }

    subject { new_query }

    context "#unwind" do
        it_behaves_like "a monad"
    end

    context "#project" do
        it_behaves_like "a monad"
    end

    context "#group" do
        it_behaves_like "a monad"
    end

    context "#fields" do
        it_behaves_like "a monad"
    end

    context "#sort" do
        it_behaves_like "a monad"
    end

    context "#limit" do
        it_behaves_like "a monad"
    end

    context "#skip" do
        it_behaves_like "a monad"
    end

    it "average age by build" do
        result = query.unwind("$rentals") \
            .project(*%w(age weight height build gender)) \
            .project("make" => "$rentals.vehicle.make",
                "model" => "$rentals.vehicle.model",
                "year" => "$rentals.vehicle.year",
                "mileage" => "$rentals.vehicle.mileage",
                "rate" => "$rentals.vehicle.rate",
                "name" => "$rentals.location.name")
            .group(build: "$build") \
            .fields(age: { "$avg" => "$age" }, 
                weight: { "$avg" => "$weight" },
                height: { "$avg" => "$height" },
                build: { "$first" => "$build" },
                gender: { "$first" => nil },
                make: { "$first" => nil },
                model: { "$first" => nil },
                year: { "$first" => nil },
                mileage: { "$avg" => "$mileage" },
                rate: { "$avg" => "$rate" },
                location: { "$first" => nil }) \
            .where('age' => { '$gt' => 34 }) \
            .sort(age: 1)
        expect(result.count).to eq(5)
        expect(result.tuples.map { |t| t['age'].to_i }) \
            .to eq([ 34, 35, 36, 50, 52 ])
    end
end
