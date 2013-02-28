$:.push File.expand_path("../lib/kusuri", __FILE__)
require "version"

Gem::Specification.new do |gem|
    gem.name = "kusuri"
    gem.version = Kusuri::VERSION
    gem.required_rubygems_version = Gem::Requirement.new(">= 1.2")
    gem.authors = [ "Don Werve" ]
    gem.description = "Flexible search for SQL, MongoDB, Solr, and more."
    gem.summary = "Kusuri implements a search parser and compiler for converting user-provided searches into queries against a variety of backends, such as ActiveRecord, Sequel, MongoDB, Solr and ElasticSearch."
    gem.email = "don@madwombat.com"
    gem.files = %w(.gitignore README.md LICENSE Rakefile Gemfile
        kusuri.gemspec)
    gem.files.concat(Dir["lib/**/*.rb"])
    gem.files.concat(Dir["spec/**/*.rb"])
    gem.files.concat(Dir["spec/**/*.yml"])
    gem.homepage = "http://github.com/matadon/kusuri"
    gem.has_rdoc = false
    gem.require_paths = [ "lib" ]
    gem.rubygems_version = "1.8"
    gem.add_dependency("treetop", ">= 1.4.0")
    gem.add_dependency("polyglot")
    gem.add_development_dependency("rspec", ">= 2.12.0")
    gem.add_development_dependency("rspec-core", ">= 2.12.0")
    gem.add_development_dependency("simplecov", ">= 0.7")
end
