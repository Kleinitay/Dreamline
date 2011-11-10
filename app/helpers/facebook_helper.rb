module FacebookHelper

  def fb_oauth
    @oauth ||= Koala::Facebook::OAuth.new(FB_APP_ID, FB_APP_SECRET, FB_SITE_URL)
  end

  def fb_graph
    @graph ||= Koala::Facebook::API.new(fb_access_token)
  end

  def fb_access_token(token = nil)
    @fb_access_token ||= if session['fb_access_token']
      session['fb_access_token']
    elsif fb_signed_request && fb_signed_request['oauth_token']
      session['fb_access_token'] = fb_signed_request['oauth_token']
    elsif cookies["fbsr_#{FB_APP_ID}"]
      session['fb_access_token'] = fb_oauth.get_user_info_from_cookie(cookies)['access_token']
    else
      session['fb_access_token'] = fb_oauth.get_app_access_token
    end
  end

  def fb_signed_request
    if !@fb_signed_request && params['signed_request']
      @fb_signed_request = session['fb_signed_request'] = fb_oauth.parse_signed_request(params['signed_request'])
    elsif session['fb_signed_request']
      @fb_signed_request ||= session['fb_signed_request']
    elsif @fb_signed_request
      @fb_signed_request
    else
      Rails.logger.debug "Could not set fb_signed_request!"
      Rails.logger.debug "session => #{session.inspect}"
      nil
    end
  end
  
  def fb_logout_url
     "https://www.facebook.com/logout.php?next=#{url_after_destroy}&access_token=#{fb_access_token}"
  end

end
