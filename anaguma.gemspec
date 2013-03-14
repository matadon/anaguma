$:.push File.expand_path("../lib/anaguma", __FILE__)
require "version"

Gem::Specification.new do |gem|
    gem.name = "anaguma"
    gem.version = Anaguma::VERSION
    gem.required_rubygems_version = Gem::Requirement.new(">= 1.2")
    gem.authors = [ "Don Werve" ]
    gem.description = (<<-END).strip.gsub(/\s+/, ' ')
        Surprisingly usable search for ActiveRecord, Sequel, MongoDB, and more.
    END
    gem.summary = (<<-END).strip.gsub(/\s+/, ' ')
        Anaguma provides tools for compiling frontend search strings into 
        into backend queries.
    END
    gem.email = "don@madwombat.com"
    gem.files = %w(.gitignore README.md LICENSE Rakefile Gemfile
        anaguma.gemspec)
    gem.files.concat(Dir["lib/**/*.rb"])
    gem.files.concat(Dir["spec/**/*.rb"])
    gem.files.concat(Dir["spec/**/*.yml"])
    gem.homepage = "http://github.com/matadon/anaguma"
    gem.has_rdoc = false
    gem.require_paths = [ "lib" ]
    gem.rubygems_version = "1.8"
    gem.add_dependency("treetop", ">= 1.4.0")
    gem.add_dependency("polyglot")
    gem.add_development_dependency("rspec", ">= 2.12.0")
    gem.add_development_dependency("rspec-core", ">= 2.12.0")
    gem.add_development_dependency("simplecov", ">= 0.7")
    gem.add_development_dependency("fuubar")
    gem.add_development_dependency("activerecord-nulldb-adapter")
    gem.add_development_dependency("sqlite3")
end
