class ApplicationController < ActionController::Base
  include Clearance::Authentication
  include helper::FacebookHelper
  #protect_from_forgery Moozly: disabling for Facebook -Koala


  def parse_facebook_cookies
    unless signed_in?
      begin

        fb_id = session['fb_uid']
        if fb_id #Logged in with Facebook
          user = User.find_by_fb_id(fb_id)
          if user
            sign_in(user)
          else
            subscribe_new_fb_user(fb_id) # new Facebook user
          end
        end
      rescue Exception=>e
        render :text => "Session Has gone away. Please refresh and try again."
      end
    end
  end



  def home
    url = signed_in? ? "/video/latest" : "/sign_in"
    redirect_to(url)
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
  
  def subscribe_new_fb_user(fb_id)
    profile = fb_graph.get_object("me")
    nick = profile["name"]
    email = profile["email"]
    fb_id = profile["id"]
    user = User.create(:status => 2, :nick => nick, :email => email, :fb_id => fb_id)
    sign_in(user)
  end
  
end
