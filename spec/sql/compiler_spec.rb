require "spec_helper"
require "kusuri/sql/compiler"

describe Kusuri::Sql::Compiler do
    let(:compiler) { Class.new(Kusuri::Sql::Compiler) }

    let(:instance) { compiler.new }

    context "#parse" do
        def parse(query)
            result = instance.parse(query)
            expect(result).to be_a(Kusuri::Sql::Fragment)
            result
        end
    
        it "empty query" do
            result = parse("")
            expect(result.sql).to eq("")
            expect(result.sql_binds).to be_empty
        end

        it "unmatched fields" do
            result = parse("created < yesterday")
            expect(result.sql).to eq("")
            expect(result.sql_binds).to be_empty
        end

        it "builds a query" do
            compiler.match(:string, field: :email)
            compiler.rule(:string) { where(field => value) }
            result = parse("email: alice@gmail.com")
            expect(result.sql).to eq("where email = ?")
            expect(result.sql_binds).to eq(%w(alice@gmail.com))
        end
    end

    # match a column against a value
    # coerce a value into a sql type
    # perform a fulltext match on a 

    # it "#table" do
    #     compiler_class.table("users")
    #     compiler.table.should == "users"
    # end

    # context "#compile" do
    #     before(:each) do
    #         compiler_class.class_eval do
    #             table :users
    # table :users

    # # Map age to a SQL function on a column.
    # map age: { column: "extract(year from age(birthday))",
    #     type: :integer }
    
    # # A field that allows the user to match against multiple values on the
    # # backend; this sets up a .match for both first_name or last_name from
    # # the value of name
    # map name: %w(first_name last_name),
    #     eyes: 'eye_color'

    # # A manually-specified rule; this would override any previously-set
    # # :target or :match
    # match license: :drivers_license

    # # No field means try to map on all fields.
    # default :all

    # def drivers_license(term)
    #     skip_default_negative_handling
    #     where("lower(drivers_license) #{operator_for(term)} lower(?)",
    #         term.value)
    # end

    #             default :all

    #             match :user_field, field: :user

    #             match :email_field, field: :email

    #             match :updated_field, field: :updated

    #             match :company_field, field: :company

    #             def user_field(term)
    #                 where("users.name #{operator} ?", term.value)
    #             end

    #             def email_field(term)
    #                 where("users.email #{operator} ?", term.value)
    #             end

    #             def updated_field(term)
    #                 where("users.updated #{operator} ?", term.value)
    #             end

    #             def company_field(term)
    #                 join("left join companies on users.company_id = companies.id")
    #                 if(term.not?)
    #                     where("(companies.name != ? or companies.name is null)",
    #                         term.value)
    #                 else
    #                     where("companies.name = ?", term.value)
    #                 end
    #             end
    #         end
    #     end


    #     it "matches a field" do
    #         result = compiler.parse("user: don")
    #         result.sql.should match_ignoring_whitespace """
    #             select * from users where users.name = ?"""
    #         result.sql_binds.should eq(%w(don))
    #     end

    #     it "handles or" do
    #         result = compiler.parse """
    #             user: don or email: bob@google.com or updated < yesterday """
    #         result.sql.should match_ignoring_whitespace """
    #             select * from users
    #             where (users.name = ? or users.email = ?
    #                 or users.updated < ?) """
    #         result.sql_binds.should == %w(don bob@google.com yesterday)
    #     end

    #     it "handles not" do
    #         result = compiler.parse """
    #             user: don and not email: bob@google.com updated: today"""
    #         result.sql.should match_ignoring_whitespace """
    #             select * from users
    #             where users.name = ?
    #                 and not users.email = ?
    #                 and users.updated = ?"""
    #         result.sql_binds.should == %w(don bob@google.com today)
    #     end

    #     it "joins" do
    #         result = compiler.parse """
    #             user: don company: widgets"""
    #         result.sql.should match_ignoring_whitespace """
    #             select * from users
    #             left join companies on users.company_id = companies.id
    #             where (users.name = ? and companies.name = ?)"""
    #         result.sql_binds.should == %w(don widgets)
    #     end

    #     it "join with negation" do
    #         result = compiler.parse """
    #             user: don not company: widgets"""
    #         result.sql.should match_ignoring_whitespace """
    #             select * from users
    #             left join companies on users.company_id = companies.id
    #             where ((users.name = ?) and 
    #             (companies.name != ? or companies.name is null))"""
    #         result.sql_binds.should == %w(don widgets)
    #     end
    # end
end
