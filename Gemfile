source :rubygems
gemspec

def gem_available?(name)
    begin
        Gem::Specification.find_by_name(name)
        true
    rescue Gem::LoadError
        false
    end
end

gem 'mongoid' if gem_available?('mongoid')
