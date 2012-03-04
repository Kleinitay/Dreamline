# Load the rails application
require File.expand_path('../application', __FILE__)

CommonData = YAML::load(File.read('config/common_data.yml'))

# Initialize the rails application
Dreamline::Application.initialize!

Dreamline::Application.configure do
    config.action_controller.allow_forgery_protection = false
    config.gem "koala"
end

# for Facebook Connect
FB_APP_KEY = Facebook::APP_ID
if Rails.env.production?
  FB_APP_SECRET = "379c4af3ea5265646256b5fcc0cde637"
else
  FB_APP_SECRET = "2eab4df3fb3f1397d6f6ddca929db4af"
end
FB_APP_ID = Facebook::APP_ID
if Rails.env.production?
  FB_SITE_URL = "http://ec2-184-72-185-12.compute-1.amazonaws.com/" #temp => http:www.vtago.com
else
  FB_SITE_URL = "http://localhost:3000/"
end


