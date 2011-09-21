# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Dreamline::Application.initialize!

CommonData = YAML::load(File.read('config/common_data.yml'))