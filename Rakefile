require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :db do
    namespace :postgres do
        desc "Create a postgres test database."
        task :create do
            require 'active_record'
            require 'highline'

            # Load database configuration.
            config = YAML.load(File.read(File.join(File.dirname(__FILE__),
                'spec/support/database.yml')))['postgresql']
            encoding = config['encoding'] || ENV['CHARSET'] || 'utf8'

            # Connect as a privileged user.
            prompt = "Postgres password for #{ENV['USER']}: "
            password = HighLine.new.ask(prompt) { |q| q.echo = false }
            ActiveRecord::Base.establish_connection(config.merge( \
                'username' => ENV['USER'],
                'password' => password,
                'database' => 'postgres', 
                'schema_search_path' => 'public'))

            # Create the user only if it doesn't exist.
            roles = ActiveRecord::Base.connection.select_values("""
                select rolname from pg_roles""")
            if(roles.include?(config['username']))
                puts("User exists, skipping create user.")
            else
                ActiveRecord::Base.connection.execute(<<-END)
                    create user #{config['username']} createdb login
                    encrypted password '#{config['password']}'
                END
            end

            # Re-connect as the owner of our new database.
            ActiveRecord::Base.establish_connection(config.merge( \
                'database' => 'postgres', 
                'schema_search_path' => 'public'))

            # Create the database only if it doesn't exist.
            databases = ActiveRecord::Base.connection.select_values("""
                select datname from pg_database""")
            if(databases.include?(config['database']))
                puts("Database exists, skipping create database.")
            else
                ActiveRecord::Base.connection.create_database( \
                    config['database'], config.merge('encoding' => encoding))
            end

            # Verify that we can access it.
            ActiveRecord::Base.establish_connection(config)
        end

        desc "Destroy the postgres test database."
        task :destroy do
            require 'active_record'
            require 'highline'

            # Load database configuration.
            config = YAML.load(File.read(File.join(File.dirname(__FILE__),
                'spec/support/database.yml')))['postgresql']
            encoding = config['encoding'] || ENV['CHARSET'] || 'utf8'

            # Connect as a privileged user.
            prompt = "Postgres password for #{ENV['USER']}: "
            password = HighLine.new.ask(prompt) { |q| q.echo = false }
            ActiveRecord::Base.establish_connection(config.merge( \
                'username' => ENV['USER'],
                'password' => password,
                'database' => 'postgres', 
                'schema_search_path' => 'public'))

            # Drop the user and database.
            ActiveRecord::Base.connection.execute(<<-END)
                drop database if exists #{config['database']}
            END
            ActiveRecord::Base.connection.execute(<<-END)
                drop user if exists #{config['username']}
            END
        end

    end
end
