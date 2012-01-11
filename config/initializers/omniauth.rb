Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook,  Facebook::APP_ID,  Facebook::SECRET, {:client_options => {:ssl => {:ca_file => "#{Rails.root}/config/ca"}}}
end