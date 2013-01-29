module MongoidTesting
    def self.test(spec, detail, &block)
        description = "mongoid#{detail.nil? ? "" : " #{detail}"}"
        spec.describe(description) {
            MongoidTesting.each_database(self, &block) }
    end

    def self.each_database(spec, &block)
        return(spec.pending("gem not installed")) unless setup?
        config_file = File.join(File.dirname(__FILE__), 'mongoid.yml')
        Mongoid.load!(config_file, :mongodb)
        begin
            load_fixtures
            spec.context(&block)
        ensure
            # FIXME
            $stderr.puts "FIXME: Clean up after Mongo test finishes"
            # %w(users locations vehicles).each { |collection|
            #     Mongoid.default_session[collection].find.remove_all }
        end
    end

    def self.setup?
        return(@setup) if @setup
        begin
            require 'mongoid'
            setup_mongoid_models
            @setup = true
        rescue LoadError
            @setup = false
        end
    end

    def self.build_mongoid_model(name, &block)
        klass = Class.new
        klass.send(:include, Mongoid::Document)
        klass.class_eval(&block)
        const_set(name, klass)
    end

    def self.setup_mongoid_models
        build_mongoid_model("User") do
            store_in collection: 'users'
            embeds_many :rentals,
                inverse_class_name: "MongoidTesting::Rental"
            field :first_name, type: String
            field :last_name, type: String
            field :email, type: String
            field :password, type: String
            field :address, type: String
            field :drivers_license, type: String
            field :age, type: Integer
            field :gender, type: String
            field :build, type: String
            field :height, type: Float
            field :weight, type: Float
            field :eye_color, type: String
            field :birthday, type: Date
            field :staff, type: Boolean
        end

        build_mongoid_model("Rental") do
            embedded_in :user
            embeds_one :vehicle,
                inverse_class_name: "MongoidTesting::Vehicle"
            embeds_one :location,
                inverse_class_name: "MongoidTesting::Location"
            field :started_at, type: Time
            field :finished_at, type: Time
        end

        build_mongoid_model("Vehicle") do
            embedded_in :rental, inverse_of: :vehicles
            field :make, type: String
            field :model, type: String
            field :year, type: Integer
            field :color, type: String
            field :rate, type: Float
            field :mileage, type: Integer
        end

        build_mongoid_model("Location") do
            embedded_in :rental, inverse_of: :locations
            field :name, type: String
            field :timezone, type: String
            field :latitude, type: Float
            field :longitude, type: Float
        end
    end

    def self.sanitize_timestamps_in_hash(unsanitized_hash)
        unsanitized_hash.inject({}) do |result, pair|
            key, value = pair
            case(value.class.to_s.downcase.to_sym)
            when :hash
                result[key] = sanitize_timestamps_in_hash(value)
            when :array
                result[key] = value.map { |i| sanitize_timestamps_in_hash(i) }
            when :date
                result[key] = value.to_time.utc.to_i
            else
                result[key] = value
            end
            result
        end
    end

    #
    # Mongoid supports embedded documents, so we're going to embed 
    # rentals under locaions. Mongoid doesn't support any Date or Time
    # types, so we need to turn those into UTC integer timestamps first
    #
    def self.load_fixtures
        session = Mongoid.default_session
        fixtures_file = File.join(File.dirname(__FILE__), 'fixtures.yml')
        fixtures = sanitize_timestamps_in_hash( \
            YAML.load(File.read(fixtures_file)))

        collection = session[:users] and collection.find.remove_all
        fixtures[:users].each { |i| collection.insert(i) }

        rentals_by_user = fixtures[:rentals].inject({}) do |result, rental|
            rental = rental.dup
            user_id = rental.delete(:user_id)
            location_id = rental.delete(:location_id)
            rental['location'] = fixtures[:locations][location_id] \
                or next(result)
            vehicle_id = rental.delete(:vehicle_id)
            rental['vehicle'] = fixtures[:vehicles][vehicle_id] \
                or next(result)
            (result[user_id] ||= []) << rental
            result
        end

        rentals_by_user.each do |id, rentals_for_user|
            user = session[:users].find(id: id)
            user.modify("$set" => { rentals: rentals_for_user })
        end
    end
end
