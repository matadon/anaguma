require 'spec_helper'
require 'kusuri/compiler'

describe Kusuri::Compiler do
    context ".match" do
        let(:compiler_class) do
            Class.new(Kusuri::Compiler) do
                def target(rule)
                    @hits ||= 0
                    @hits += 1
                end

                def hit?
                    @hits ||= 0
                    raise("Rule matched multiple times.") unless (@hits < 2)
                    @hits == 1
                end
            end
        end

        let(:compiler) { compiler_class.new }

        let(:term) do 
            mock = double("term")
            mock.stub(:field).and_return('name')
            mock.stub(:value).and_return('alice')
            mock
        end

        it "target defined" do
            lambda { compiler_class.match(:target) } \
                .should_not raise_error(NoMethodError)
        end

        it "target not defined" do
            lambda { compiler_class.match(:nope) } \
                .should raise_error(NoMethodError)
        end

        it "if block match" do
            compiler_class.match(:target, :if => Proc.new { true })
            compiler.compile(term)
            compiler.should be_hit
        end

        it "if block doesn't match" do
            compiler_class.match(:target, :if => Proc.new { false })
            compiler.compile(term)
            compiler.should_not be_hit
        end

        it "if method match" do
            compiler_class.send(:define_method, :condition) { |t| true }
            compiler_class.match(:target, :if => :condition)
            compiler.compile(term)
            compiler.should be_hit
        end

        it "if method doesn't match" do
            compiler_class.send(:define_method, :condition) { |t| false }
            compiler_class.match(:target, :if => :condition)
            compiler.compile(term)
            compiler.should_not be_hit
        end

        it "unless block match" do
            compiler_class.match(:target, :unless => Proc.new { false })
            compiler.compile(term)
            compiler.should be_hit
        end

        it "unless block doesn't match" do
            compiler_class.match(:target, :unless => Proc.new { true })
            compiler.compile(term)
            compiler.should_not be_hit
        end

        it "unless method match" do
            compiler_class.send(:define_method, :condition) { |t| false }
            compiler_class.match(:target, :unless => :condition)
            compiler.compile(term)
            compiler.should be_hit
        end

        it "unless method doesn't match" do
            compiler_class.send(:define_method, :condition) { |t| true }
            compiler_class.match(:target, :unless => :condition)
            compiler.compile(term)
            compiler.should_not be_hit
        end

        it "field symbol matches" do
            compiler_class.match(:target, :field => :name)
            compiler.compile(term)
            compiler.should be_hit
        end

        it "field string matches" do
            compiler_class.match(:target, :field => 'name')
            compiler.compile(term)
            compiler.should be_hit
        end

        it "field accepts array" do
            compiler_class.match(:target, :field => %w(name birthday))
            compiler.compile(term)
            compiler.should be_hit
        end

        it "field doesn't match" do
            compiler_class.match(:target, :field => :birthday)
            compiler.compile(term)
            compiler.should_not be_hit
        end

        it "fields accepts array" do
            compiler_class.match(:target, :fields => %w(name birthday))
            compiler.compile(term)
            compiler.should be_hit
        end

        it "first matching rule" do
            compiler_class.match(:target, :field => :name)
            compiler_class.match(:target, :field => :name)
            compiler.compile(term)
            compiler.should be_hit
        end

        it ".default" do
            compiler_class.send(:define_method, :other) { |t| true }
            compiler_class.match(:other, :field => :birthday)
            compiler_class.default(:target)
            compiler.compile(term)
            compiler.should be_hit
        end

        it "#compile chainable" do
            compiler.compile(term).should == compiler
        end
    end
end
