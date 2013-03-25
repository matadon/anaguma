require "spec_helper"
require "anaguma/mongoid/searcher"

MongoidTesting.test(self, Anaguma::Mongoid::Searcher) do
    let(:base) { Anaguma::Mongoid::Query.new(MongoidTesting::User.all) }

    let(:klass) do 
        Class.new(Anaguma::Mongoid::Searcher) do
            rule(:name) do |term|
                return unless (term.field == 'name')
                term.consume!
                fields = %w(first_name last_name)
                any_of { fields.each { |f| compare(term, field: f) } }
            end

            rule(:flags) do |term|
                return unless (term.field == 'is')
                term.consume!
                where(staff: (not term.negated?)) \
                    if (term.value.downcase == 'staff')
            end

            rule(:rental) do |term|
                return unless (term.field == 'rental')
                term.consume!
                fields = %w(rentals.vehicle.make rentals.vehicle.model
                    rentals.vehicle.year rentals.vehicle.color
                    rentals.vehicle.rate rentals.vehicle.mileage)
                any_of { fields.each { |f| compare(term, field: f) } }
            end

            rule(:generic) do |term|
                next(compare(term)) if term.field
                fields = %w(first_name last_name drivers_license build
                    gender age)
                any_of { fields.each { |f| compare(term, field: f) } }
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
