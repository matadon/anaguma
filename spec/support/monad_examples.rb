shared_examples_for "a monad" do |options = {}|
    let(:method) do 
        return(options[:method]) if options[:method]
        description = self.class.ancestors[1].description
        raise(ArgumentError, "Context description not a string") \
            unless description.is_a?(String)
        match = description.match(/\#([a-z][\w\?\!]+)/)
        raise(ArgumentError, "Context description lacking #method") \
            unless match
        match[1]
    end

    let(:target) { options[:target] || subject }

    it("chainable") { expect(target.send(method)).to be_a(target.class) }

    it("immutable") { expect(target.send(method)).to_not be(target) }
end
