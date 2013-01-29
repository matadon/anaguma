require "spec_helper"
require "kusuri/searchable"

ActiveRecordTesting.test(self, "Searchable") do
    before(:all) { ActiveRecordTesting::User.send(:include,
        Kusuri::Searchable) }

    # before(:all) { ActiveRecordTesting::Location.send(:include,
    #     Kusuri::Searchable) }

    #
    # Run one query, and check the result tuples against a block. We take
    # care of comparing tuples to instantiated models and counting the
    # returned fields here.
    #
    def search(query, &block)
        result = ActiveRecordTesting::User.search(query)

        expect(result.tuples).to be_a(Array)
        expect(result.tuples).to be_all { |r| r.instance_of?(Hash) }

        expect(result.instances).to be_a(Array)
        expect(result.instances).to be_all { |r|
            r.instance_of?(ActiveRecordTesting::User) }

        expect(result.tuples.count).to eq(result.instances.count)

        expect(result.tuples.each_with_index).to be_all do |tuple, index|
            instance = result.instances[index]
            tuples.all? { |k, v| instance.send(k).should == v }
        end

        expect(result.instances).to be_all(&block) if block_given?
        expect(result).to_not be_empty if block_given?

        result
    end
        
        # tuples
        # join on locations, rentals, vehicles
        # group by user_id, vehicle, location, timezone

        # instantiate:
        # single string field (eye color)
        # string matched across two fields
        # number (age)
        # date (birthday)
        # time
        # fieldless search that matches multiple fields
        # sort ordering
        #
        # find the thing
        # tuples should match
        # instances should match
        # instances should be in tuple order

    context "simple queries" do
        context "string" do
            pending("equals") { search("name: emma") { |instance|
                instance.first_name == "emma" } }

            # when an alias is inverted, we need to either be able to invert
            # the conditions, or we just ditch aliasing entirely and we do
            # this shit at the query level.
 
            pending("not-equals") { search("name: emma") { |instance|
                instance.first_name != "emma" } }

            # this means either first or last name should be greater
            pending("greater") { search("name > emma") { |instance|
                instance.first_name > "emma" } }

            pending("less") { search("name < emma") { |instance|
                instance.first_name < "emma" } }

            pending "greater-or-equal" do
                search("name >= emma") { |instance|
                    instance.first_name >= "emma" }
            end

            pending "less-or-equal" do
                search("name <= emma") { |instance|
                    instance.first_name <= "emma" }
            end

            pending "mutually exclusive" do
                result = search("name: emma and name: liam")
                expect(result.count).to eq(0)
            end

            pending "any of" do
                search("name: emma or name: liam") { |instance|
                    %w(emma liam).include?(instance.first_name) }
            end
        end

        # context "date" do
        #     it "equals" do
        #         results = search("birthday: "29 Feb 1976"")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.birthday == "29 Feb 1976" }
        #     end

        #     it "not-equals" do
        #         results = search("not birthday: "29 Feb 1976"")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.birthday != "29 Feb 1976" }
        #     end

        #     it "greater" do
        #         results = search("birthday > "29 Feb 1976"")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.birthday > "29 Feb 1976" }
        #     end

        #     it "less" do
        #         results = search("birthday < "29 Feb 1976"")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.birthday < "29 Feb 1976" }
        #     end

        #     it "greater-or-equal" do
        #         results = search("birthday >= "29 Feb 1976"")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.birthday >= "29 Feb 1976" }
        #     end

        #     it "less-or-equal" do
        #         results = search("birthday <= "29 Feb 1976"")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.birthday <= "29 Feb 1976" }
        #     end

        #     it "inside range" do
        #         results = search("""birthday > "29 Feb 1976"
        #             and birthday < "30 Nov 1984" """)
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| (r.birthday > "29 Feb 1976") \
        #             and (r.birthday < "30 Nov 1984") }
        #     end

        #     it "outside range" do
        #         results = search("""birthday < "29 Feb 1976"
        #             or birthday > "30 Nov 1984" """)
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| (r.birthday < "29 Feb 1976") \
        #             or (r.birthday > "30 Nov 1984") }
        #     end

        #     it "approximately" do
        #         results = search("birthday ~ "29 Feb 1976"")
        #         expect(results.count).to eq(1)
        #         # results).to be_all { |r| (r.birthday < "29 Feb 1976") \
        #         #     or (r.birthday > "30 Nov 1984") }
        #     end
        # end

        # context "number" do
        #     it "equals" do
        #         results = search("weight: 165")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.weight == 165 }
        #     end

        #     it "not-equals" do
        #         results = search("not weight: 165")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.weight != 165 }
        #     end

        #     it "greater" do
        #         results = search("weight > 165")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.weight > 165 }
        #     end

        #     it "less" do
        #         results = search("weight < 165")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.weight < 165 }
        #     end

        #     it "greater-or-equal" do
        #         results = search("weight >= 165")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.weight >= 165 }
        #     end

        #     it "less-or-equal" do
        #         results = search("weight <= 165")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| r.weight <= 165 }
        #     end

        #     it "inside range" do
        #         results = search("weight > 165 and weight < 200")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| (r.weight > 165) \
        #             and (r.weight < 200) }
        #     end

        #     it "outside range" do
        #         results = search("weight < 165 or weight > 200")
        #         expect(results.count).to eq(1)
        #         expect(results).to be_all { |r| (r.weight < 165) \
        #             or (r.weight > 200) }
        #     end

        #     it "approximately" do
        #         results = search("weight ~ 165")
        #         expect(results.count).to eq(1)
        #         # results).to be_all { |r| (r.weight < 165) \
        #         #     or (r.weight > 200) }
        #     end
        # end

        # it "can"t search a protected field" do
        #     results = search("password: cowboy")
        #     expect(results.count).to eq(subject.count)
        #     expect(results).to be_any { |r| r.password != "cowboy" }
        # end

        # it "multiple fields with different types", :focus do
        #     results = search("blue or jacked")
        #     expect(results.count).to eq(-1)
        #     expect(results).to be_all { |r| r.eye_color == "blue" \
        #         or r.build == "jacked" }
        # end

        # pending "case-insensitive"

        # pending "string wildcards"

    #     #
    #     # none of the join queries make sense for mongodb, except in the
    #     # context of embedded documents...
    #     #

    #     context "joins" do
    #         it "single" do
    #             # everybody that has rented a car from kahriz
    #             results = search("location: kahriz")
    #             results.count).to eq(37)
    #             user_ids = results.map(&:id).sort
                
    #             # select distinct users.id
    #             # from users
    #             # left join rentals on rentals.user_id = users.id
    #             # left join locations on rentals.location_id = locations.id
    #             # left join vehicles on vehicles.id = rentals.vehicle_id
    #             # where locations.name = "Kahriz";
    #         end

    #         it "multiple" do
    #             # everybody that has rented a vw from kahriz
    #             results = search("location: kahriz and make: vw")
    #             results.count).to eq(30)
    #             # select distinct users.id
    #             # from users
    #             # left join rentals on rentals.user_id = users.id
    #             # left join locations on rentals.location_id = locations.id
    #             # left join vehicles on vehicles.id = rentals.vehicle_id
    #             # where locations.name = "Kahriz" and vehicles.make = "VW";
    #         end

    #         it "inverse match single" do
    #             # everybody that has rented something that isn"t a ford
    #             results = search("not make: ford")
    #             results.count).to eq(49)

    #             # select users.id
    #             # from users
    #             # left join rentals on rentals.user_id = users.id
    #             # left join locations on rentals.location_id = locations.id
    #             # left join vehicles on vehicles.id = rentals.vehicle_id
    #             # group by users.id
    #             # having bool_or(vehicles.make = "Ford") = false;
    #         end

    #         it "inverse match multiple " do
    #             # everybody that has rented something that isn"t a ford
    #             # from everywhere but Azadshahr
    #             results = search("""
    #                 not make: ford and not location: azadshahr""")
    #             results.count).to eq(-1)
    #             # select distinct users.id
    #             # from users
    #             # left join rentals on rentals.user_id = users.id
    #             # left join locations on rentals.location_id = locations.id
    #             # left join vehicles on vehicles.id = rentals.vehicle_id
    #             # where vehicles.make != "Ford"
    #             # and locations.name != "Azadshahr";
    #         end

    #         it "union single" do
    #             results = search("make: ford and rate < 20 or rate > 50")
    #             results.count).to eq(-1)
    #             # everybody that has spent either less than $20 
    #             # or more than $50 on a ford
    #         end

    #         it "union multiple" do
    #             results = search("""location: "Wadi ar Ramliyat"
    #                 and rate < 20 or rate > 50""")
    #             results.count).to eq(-1)
    #             # everybody that has spent less than $20
    #             # or more than $50
    #             # on a vehicle from Wadi ar Ramliyat
    #         end

    #         it "intersect single" do
    #             results = search("make: ford rate > 20 rate < 50")
    #             results.count).to eq(-1)
    #             # everybody that has spent between $20 and $50
    #             # on a ford
    #         end

    #         it "intersect multiple" do
    #             results = search("""location: "Wadi ar Ramliyat"
    #                 and rate > 20 and rate < 50""")
    #             results.count).to eq(-1)
    #             # everybody that has spent between $20 and $50
    #             # on a vehicle from Wadi ar Ramliyat
    #         end
    #     end

    #     context "joins with aggregates" do
    #         # everybody that has rented a car for longer than a week
    #         #     rented > "7 days"
    #         #     grouped by users.id
    #         # spent more than $500 on rentals in a year
    #         #     spent > 500
    #         #     grouped by users.id
                
    #         # select users.id,
    #         #     min(rentals.finished_at - rentals.started_at),
    #         #     max(rentals.finished_at - rentals.started_at),
    #         #     sum(rentals.finished_at - rentals.started_at)
    #         # from users
    #         # left join rentals on rentals.user_id = users.id
    #         # left join locations on rentals.location_id = locations.id
    #         # left join vehicles on vehicles.id = rentals.vehicle_id
    #         # where (rentals.finished_at - rentals.started_at) > 14
    #         # group by users.id
    #     end
    end
end
