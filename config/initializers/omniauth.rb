Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook,  Facebook::APP_ID,  Facebook::SECRET, {:scope => 'publish_stream, email', :client_options => {:ssl => {:ca_file => "#{Rails.root}/config/ca"}}}
end