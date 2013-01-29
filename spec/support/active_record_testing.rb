#
# Encapsulates setup and teardown of ActiveRecord databases for RSpec. We
# want to allow for running the test suite without any active record tests,
# both for running non-integration tests, and for developers that don't need
# to set up the full test environment on their system for all supported
# databases.
#
# Each set of tests run on a database is guaranteed a working ActiveRecord
# setup with fixtures, and a context labeled with the database name.
#
module ActiveRecordTesting
    MIGRATIONS = { 
        users: { first_name: :string, last_name: :string,
            email: :string, password: :string, address: :text,
            drivers_license: :string, age: :integer, gender: :string,
            build: :string, height: :integer, weight: :integer,
            eye_color: :string, birthday: :date,
            banned: [ :boolean, default: false ] },
        vehicles: { make: :string, model: :string, year: :integer,
            color: :string, mileage: :integer, rate: :float },
        locations: { name: :string, timezone: :string, latitude: :float,
            longitude: :float, },
        rentals: { location_id: :integer, vehicle_id: :integer,
            user_id: :integer, started_at: :date, finished_at: :date } }

    def self.test(spec, detail, &block)
        description = "active_record#{detail.nil? ? "" : " #{detail}"}"
        spec.describe(description) {
            ActiveRecordTesting.each_database(self, &block) }
    end

    def self.each_database(spec, &block)
        return(spec.pending("gem not installed")) unless setup?

        databases = YAML.load(File.read(File.join(File.dirname(__FILE__),
            'database.yml')))
        databases.each do |database, config|
            begin
                ActiveRecord::Base.establish_connection(config)
                migrate(:up)
                load_fixtures
                begin
                    spec.context(database, &block)
                ensure
                    # FIXME
                    $stderr.puts "FIXME: Clean up database when done."
                    # migrate(:down)
                end
            rescue LoadError
                spec.context(database) { pending("gem not installed") }
            rescue => error
                raise unless (error.to_s =~ /password/)
                spec.context(database) { pending("not setup for testing") }
            end
        end
    end

    def self.setup?
        return(@setup) if @setup
        begin
            require 'active_record'
            setup_active_record_models
            @setup = true
        rescue LoadError
            @setup = false
        end
    end

    def self.build_active_record_model(name, &block)
        const_set(name, Class.new(ActiveRecord::Base, &block))
    end

    def self.setup_active_record_models
        build_active_record_model("User") do
            has_many :rentals
            has_many :vehicles, through: :rentals
            has_many :locations, through: :rentals
        end

        build_active_record_model("Vehicle") do
            has_many :rentals
            has_many :locations, through: :rentals
            has_many :users, through: :rentals
        end

        build_active_record_model("Location") do
            has_many :rentals
            has_many :vehicles, through: :rentals
            has_many :users, through: :rentals
        end

        build_active_record_model("Rental") do
            belongs_to :user
            belongs_to :location
            belongs_to :vehicle
        end
    end

    def self.migrate(direction)
        @migration ||= Class.new(ActiveRecord::Migration) do
            def up
                MIGRATIONS.each do |table, columns|
                    next(execute("delete from #{table}")) \
                        if table_exists?(table)
                    create_table(table) do |t|
                        columns.each do |name, *args|
                            args.flatten!
                            type = args.shift
                            t.send(type, name, *args)
                        end
                    end
                end
            end

            def down
                MIGRATIONS.keys.reverse.each { |table|
                    drop_table(table) if table_exists?(table) }
            end
        end

        ActiveRecord::Migration.verbose = false
        @migration.migrate(direction)
        ActiveRecord::Migration.verbose = true
    end

    def self.load_fixtures
        connection = ActiveRecord::Base.connection
        fixtures = YAML.load(File.read(File.join(File.dirname(__FILE__),
            'fixtures.yml')))
        fixtures.each_pair do |table, values|
            values.each { |v| connection.insert_fixture(v, table) }
        end
    end
end

