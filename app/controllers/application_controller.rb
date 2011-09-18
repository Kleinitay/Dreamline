class ApplicationController < ActionController::Base
  include Clearance::Authentication
  protect_from_forgery
  
  def home
  	@order = "latest"
#  	@videos = Videos.get_by_latest
  @videos = []
  end
  
  def render_404
      render(:file => "#{Rails.root}/public/404.html", :status => 404)
  end
end
