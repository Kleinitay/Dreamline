class ApplicationController < ActionController::Base
  include Clearance::Authentication
  protect_from_forgery
  
  def home
    redirect_to("/video/latest")
  end

  def render_404
      render(:file => "#{Rails.root}/public/404.html", :status => 404)
  end

  #Moozly: for controllers of listing. Redirecting /1 to no parameter.
  def redirect_first_page_to_base
    if params[:page] && params[:page].first == '1'
      uri = request.path
      redirect_to(uri.gsub("/1",""))
    end
  end
end
