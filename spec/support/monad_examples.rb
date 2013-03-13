shared_examples_for "a monad" do |options = {}|
    let(:method) do 
        options[:on] or raise('Please pass a method name in the :on option')
    end

    let(:target) { options[:target] || subject }

    it("chainable") { expect(target.send(method)).to be_a(target.class) }

    it("immutable") { expect(target.send(method)).to_not be(target) }
end
