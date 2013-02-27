require "spec_helper"
require "kusuri/mongoid/compiler"

MongoidTesting.test(self, Kusuri::Mongoid::Compiler) do
    let(:base) { Kusuri::Mongoid::Query.new(MongoidTesting::User.all) }

    let(:compiler) { Class.new(Kusuri::Mongoid::Compiler) }

    let(:instance) { compiler.new(base) }

    before :each do
        compiler.permit(%w(name age is build gender rental))
        compiler.match(:name, field: 'name')
        compiler.match(:flags, field: 'is')
        compiler.match(:age, field: 'age') { term.operator == :like }
        compiler.match(:rental, field: 'rental')
        compiler.match(:generic)
        compiler.rule(:name) { compare(term, any: %w(first_name last_name)) }
        compiler.rule(:age) do
            min, max = (term.value.to_i - 3), (term.value.to_i + 3)
            where('age' => { '$gt' => min, '$lt' => max })
        end
        compiler.rule(:flags) do
            where(staff: (not term.not?)) if (term.value.downcase == 'staff')
        end
        compiler.rule(:rental) do
            compare(term, any: %w(rentals.vehicle.make
                rentals.vehicle.model rentals.vehicle.year
                rentals.vehicle.color rentals.vehicle.rate
                rentals.vehicle.mileage))
        end
        compiler.rule(:generic) do
            next if term.matched?
            next(compare(term)) if term.field
            compare(term, any: %w(first_name last_name drivers_license 
                build gender age))
        end
    end

    def self.search(query, &block)
        it(query) do
            result = instance.search(query)
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
            expect(result).to be_empty unless block_given?
        end
    end

    context "simple queries" do
        context "string" do
           search("name: emma") { |user| user.first_name == "emma" }
 
           search("not name: emma") { |user| user.first_name != "emma" }
 
           search("name > emma") { |user| 
               (user.first_name > "emma")  or (user.last_name > "emma") }
 
           search("name < emma") { |user|
               (user.first_name < "emma") or (user.last_name < "emma") }
 
           search("name >= emma") { |user|
               (user.first_name >= "emma") or (user.last_name >= "emma") }
 
           search("name <= emma") { |user|
               (user.first_name <= "emma") or (user.last_name <= "emma") }
 
           search("name: emma and name: liam")
 
           search("name: emma or name: liam") { |user|
                %w(emma liam).include?(user.first_name) }
 
           search("name ~ e*") { |user|
               (user.first_name =~ /^e/i) or (user.last_name =~ /^e/i) }
        end

        context "number" do
           search("age: 29") { |user| user.age == 29 }
 
           search("not age: 29") { |user| user.age != 29 }
 
           search("age > 29") { |user| user.age > 29 }
 
           search("age < 29") { |user| user.age < 29 }
 
           search("age >= 29") { |user| user.age >= 29 }
 
           search("age <= 29") { |user| user.age <= 29 }
 
           search("age < 29 and age > 40")
 
           search("age < 29 or age > 40") { |user|
                ((user.age < 29) or (user.age > 40)) }
 
           search("age ~ 29") { |user|
                ((user.age > 26) and (user.age < 32)) }
        end

        context "boolean" do
            search("is: staff") { |user| user.staff? }

            search("not is: staff") { |user| not user.staff? }
        end
    end

    context "complex queries" do
        search("16738759") { |user| user.drivers_license == "16738759" }

        search("male fat") { |user|
            (user.build == 'fat') and (user.gender == 'male') }

        search("rental: Honda") { |user|
            user.rentals.any? { |r| r.vehicle.make == 'Honda' } }

        search("not rental: Ford") { |user|
            user.rentals.none? { |r| r.vehicle.make == 'Ford' } }

        search("rental: Focus or rental: Jetta") do |user|
            user.rentals.any? { |r| %w(Focus Jetta).include?(r.vehicle.model) }
        end

        search("rental: Honda rental: Ford") do |user|
            user.rentals.any? { |r| r.vehicle.make == 'Honda'} \
                and user.rentals.any? { |r| r.vehicle.make == 'Ford'} 
        end
    end

    context "#autoconfigure" do
        pending
        # we pass it User, and it sets up match rules for that user
        # user will then add their own rules afterwards
        # permit and filter will need to go above everything else.
    end
end
