RSpec::Matchers.define :match_ignoring_whitespace do |expected|
    match do |actual|
        actual.strip.gsub(/\s+/, ' ') == expected.strip.gsub(/\s+/, ' ')
    end
end
