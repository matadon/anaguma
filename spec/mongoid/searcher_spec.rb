require "spec_helper"
require "anaguma/mongoid/searcher"

MongoidTesting.test(self, Anaguma::Mongoid::Searcher) do
    let(:base) { Anaguma::Mongoid::Query.new(MongoidTesting::User.all) }

    let(:klass) do 
        Class.new(Anaguma::Mongoid::Searcher) do
            match(:name)
            match(:flags)
            match(:age)
            match(:rental)
            match(:generic)

            rule(:name) do
                return unless (term.field == 'name')
                term.reject!
                compare(term, any: %w(first_name last_name))
            end

            rule(:age) do
                return unless (term.field == 'age')
                return unless (term.operator == :like)
                term.reject!
                min, max = (term.value.to_i - 3), (term.value.to_i + 3)
                where('age' => { '$gt' => min, '$lt' => max })
            end

            rule(:flags) do
                return unless (term.field == 'is')
                term.reject!
                where(staff: (not term.not?)) \
                    if (term.value.downcase == 'staff')
            end

            rule(:rental) do
                return unless (term.field == 'rental')
                term.reject!
                compare(term, any: %w(rentals.vehicle.make
                    rentals.vehicle.model rentals.vehicle.year
                    rentals.vehicle.color rentals.vehicle.rate
                    rentals.vehicle.mileage))
            end
            rule(:generic) do
                next(compare(term)) if term.field
                compare(term, any: %w(first_name last_name drivers_license
                    build gender age))
            end
        end
    end

    let(:searcher) { klass.new(base) }

    context "simple queries" do
        context "string" do
           it { searches("name: emma") { |t| t['first_name'] == "emma" } }
           it { searches("not name: emma") { |t| t['first_name'] != "emma" } }
           it { searches("name > emma") { |t|
               (t['first_name'] > "emma")  or (t['last_name'] > "emma") } }
           it { searches("name < emma") { |t|
               (t['first_name'] < "emma") or (t['last_name'] < "emma") } }
           it { searches("name >= emma") { |t|
               (t['first_name'] >= "emma") or (t['last_name'] >= "emma") } }
           it { searches("name <= emma") { |t|
               (t['first_name'] <= "emma") or (t['last_name'] <= "emma") } }
           it { searches_and_finds_nothing("name: emma and name: liam") }
           it { searches("name: emma or name: liam") { |t|
                %w(emma liam).include?(t['first_name']) } }
           it { searches("name ~ e*") { |t|
               (t['first_name'] =~ /^e/i) or (t['last_name'] =~ /^e/i) } }
        end

        context "number" do
           it { searches("age: 29") { |t| t['age'] == 29 } }
           it { searches("not age: 29") { |t| t['age'] != 29 } }
           it { searches("age > 29") { |t| t['age'] > 29 } }
           it { searches("age < 29") { |t| t['age'] < 29 } }
           it { searches("age >= 29") { |t| t['age'] >= 29 } }
           it { searches("age <= 29") { |t| t['age'] <= 29 } }
           it { searches_and_finds_nothing("age < 29 and age > 40") }
           it { searches("age < 29 or age > 40") { |t|
                ((t['age'] < 29) or (t['age'] > 40)) } }
           it { searches("age ~ 29") { |t|
                ((t['age'] > 26) and (t['age'] < 32)) } }
        end

        context "boolean" do
            it { searches("is: staff") { |t| t['staff'] } }
            it { searches("not is: staff") { |t| not t['staff'] } }
        end
    end

    context "complex queries" do
        it { searches("16738759") { |t| t['drivers_license'] == "16738759" } }
        it { searches("male fat") { |t|
            (t['build'] == 'fat') and (t['gender'] == 'male') } }
    end
end
