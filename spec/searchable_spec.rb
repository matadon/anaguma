require "spec_helper"
require 'kusuri/searchable'

describe Kusuri::Searchable do
    subject { Kusuri::Searchable }

    it ".superclasses_for" do
        grandparent = Class.new
        parent = Class.new(grandparent)
        unrelated = Class.new
        klass = Class.new(parent)
        superclasses = subject.superclasses_for(klass)
        expect(superclasses).to include(grandparent.to_s)
        expect(superclasses).to include(parent.to_s)
        expect(superclasses).to include(klass.to_s)
        expect(superclasses).to include('Object')
        expect(superclasses).to include('BasicObject')
        expect(superclasses).not_to include(unrelated.to_s)
    end

    it ".included_modules_for" do
        alpha = Module.new
        beta = Module.new { include alpha }
        gamma = Module.new
        unrelated = Module.new
        klass = Class.new { include beta; include gamma }
        modules = subject.included_modules_for(klass)
        expect(modules).to include(alpha.to_s)
        expect(modules).to include(beta.to_s)
        expect(modules).to include(gamma.to_s)
        expect(modules).not_to include(unrelated.to_s)
    end

    it ".extended_modules_for" do
        alpha = Module.new
        beta = Module.new { include alpha }
        gamma = Module.new
        unrelated = Module.new
        klass = Class.new { extend beta; extend gamma }
        modules = subject.extended_modules_for(klass)
        expect(modules).to include(alpha.to_s)
        expect(modules).to include(beta.to_s)
        expect(modules).to include(gamma.to_s)
        expect(modules).not_to include(unrelated.to_s)
    end

    context ".compiler_for" do
        context "active_record", if: ActiveRecordTesting.setup? do
            it "model" do
                engine = subject.compiler_for(ActiveRecordTesting::User)
                expect(engine).to be(Kusuri::ActiveRecord::Compiler)
            end

            it "model subclass" do
                subclass = Class.new(ActiveRecordTesting::User)
                engine = subject.compiler_for(subclass)
                expect(engine).to be(Kusuri::ActiveRecord::Compiler)
            end
        end

        context "mongoid", if: MongoidTesting.setup? do
            it "model" do
                engine = subject.compiler_for(MongoidTesting::User)
                expect(engine).to be(Kusuri::Mongoid::Compiler)
            end

            it "model subclass" do
                subclass = Class.new(MongoidTesting::User)
                engine = subject.compiler_for(subclass)
                expect(engine).to be(Kusuri::Mongoid::Compiler)
            end
        end

        it "unsupported backend" do
            expect(lambda { subject.compiler_for(Class) }).to \
                raise_error(Kusuri::Searchable::Unsupported)
        end
    end

    context ".included into" do
        it "active_record", if: ActiveRecordTesting.setup? do
            subclass = Class.new(ActiveRecordTesting::User)
            expect(subclass).not_to respond_to(:search)
            subclass.send(:include, Kusuri::Searchable)
            expect(subclass).to respond_to(:search)
        end

        it "mongoid", if: MongoidTesting.setup? do
            subclass = Class.new(MongoidTesting::User)
            expect(subclass).not_to respond_to(:search)
            subclass.send(:include, Kusuri::Searchable)
            expect(subclass).to respond_to(:search)
        end

        it "unsupported backend" do
            subclass = Class.new
            expect(lambda { subclass.send(:include, Kusuri::Searchable) }).to \
                raise_error(Kusuri::Searchable::Unsupported)
        end
    end

    context "Kusuri::Searchable::Proxy#use" do
        let(:base) { Class.new }

        let(:proxy) { Kusuri::Searchable::Proxy.new(base) }

        it "requires a target" do
            expect(lambda { proxy.value }).to \
                raise_error(Kusuri::Searchable::ProxyWithoutTarget)
        end

        it "requires target.model" do
            bad_target = double(:target, value: 42)
            expect(lambda { proxy.use(bad_target) }).to \
                raise_error(RSpec::Mocks::MockExpectationError)

            good_target = double(:target, value: 42, model: nil)
            expect(lambda { proxy.use(good_target) }).to_not raise_error
        end

        it "delegates" do
            original_target = double(:target, value: 42, model: nil)
            expect(proxy.use(original_target).value).to equal(42)

            replacement_target = double(:target, value: 99, model: nil)
            expect(proxy.use(replacement_target).value).to equal(99)
        end
    end
end
