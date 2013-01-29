require 'timeout'
require 'benchmark'
require 'thread'
require 'simplecov'

SimpleCov.start { add_filter "spec/" }

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

support_path = File.join(File.dirname(__FILE__), 'support/**/*.rb')
Dir[support_path].each { |f| require f }

RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run focus: true
    config.run_all_when_everything_filtered = true
end
