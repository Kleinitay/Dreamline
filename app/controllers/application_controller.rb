class ApplicationController < ActionController::Base
  include Clearance::Authentication
  protect_from_forgery
  
  def home
  	@order = "latest"
#  	@videos = Videos.get_by_latest
  @videos = []
  end
end
