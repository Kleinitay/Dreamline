# Load the rails application
require File.expand_path('../application', __FILE__)

CommonData = YAML::load(File.read('config/common_data.yml'))

# Initialize the rails application
Dreamline::Application.initialize!

