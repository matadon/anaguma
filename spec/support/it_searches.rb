module ItSearches
    def searches(query, &block)
        result = searcher.search(query)
        expect(result).to_not be_empty
        expect(result).to be_all(&block)
    end

    def searches_and_finds_nothing(query)
        expect(searcher.search(query)).to be_empty
    end
end
