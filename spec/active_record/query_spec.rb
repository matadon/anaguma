require "spec_helper"
require "active_record"
require "anaguma/active_record/query"

# Query.merge(query1, query2, ..., queryN) => Query
# Query#instances => [ Model1, Model2, ..., ModelN ]
# Query#tuples => [ {}, {}, ..., {} ]
# Query#each
# Query#count
#
# IDEA: Query#format(:tuples | :instances) => Query
# IDEA: Query.monadic_builder_methods => [ :limit, :where, :offset, ... ]

describe Anaguma::ActiveRecord::Query do
    before(:all) do
        ActiveRecord::Base.establish_connection(adapter: :nulldb)
    end

    let(:relation) { ActiveRecord::Relation.new(Class.new(ActiveRecord::Base),
        Arel::Table.new('test')) }

    let(:query) { Anaguma::ActiveRecord::Query.new(relation) }

    subject { query }

    describe "#select" do
        it_behaves_like "a monad"

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

    describe "#from" do
        it_behaves_like "a monad"

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
        it_behaves_like "a monad"

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

    describe "#where" do
        it_behaves_like "a monad"

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
        it_behaves_like "a monad"

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
        it_behaves_like "a monad"

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
        it_behaves_like "a monad"

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

    describe "#limit" do
        it_behaves_like "a monad"

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
        it_behaves_like "a monad"

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

    # context ".merge" do
    #     it ":and" do
    #         first = new_query.where(build: "athletic")
    #         second = new_query.where(age: { "$gt" => 18 })
    #         third = new_query.where(gender: "male")
    #         result = Anaguma::Mongoid::Query.merge(:and, first,
    #             second, third)
    #         result.count.should == 1
    #         result.first.email.should == "noah.roberts@irow.com"
    #     end

    #     it ":or" do
    #         first = new_query.where(email: "mia.jackson@irow.com")
    #         second = new_query.where(weight: { "$gt" => 213 })
    #         third = new_query.where(first_name: "ethan")
    #         result = Anaguma::Mongoid::Query.merge(:or, first,
    #             second, third)
    #         expect(result.count).to eq(4)
    #         expect(result.map(&:email).sort).to eq(%w(daniel.king@najaf.cc
    #             ethan.brown@hotmail.com ethan.phillips@najaf.cc
    #             mia.jackson@irow.com))
    #     end
    # end

    describe ".merge" do
        pending
        # it ":and" do
        #     first = select('id').from('monkeys').joins('simians') \
        #             .where().having().group().order().limit().offset()
        # end

        # it ":or" do
        #     # first = select('id').from('monkeys').joins('simians') \
        #     #         .where().having().group().order().limit().offset().
        # end
    end

    pending "#reorder?"

    pending "#includes?"

    context "returning results from the database" do
        describe "#instances" do
            pending
        end

        describe "#tuples" do
            pending
        end

        describe "#each" do
            pending
        end

        describe "#count" do
            pending
        end

        describe "#empty?" do
            pending
        end
    end
end
