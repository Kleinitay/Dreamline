class AuthenticationController < ApplicationController
  def index
      @authetications = Authentication.all
  end

  def create
      auth = request.env["omniauth.auth"] .to_yaml
      current_user.authentications.build(:provider => auth['provider'], :uid => auth['uid'])
      session['fb_uid'] = auth['uid']
      session['fb_access_token'] =
      redirect_to authentications_url
  end

  def get_uid_and_access_token
      auth = request.env["omniauth.auth"]
      uid = auth['uid']
      token =  auth['credentials']['token']
      session['fb_uid'] = auth['uid']
      session['fb_access_token'] = auth['credentials']['token']
      parse_facebook_cookies
      redirect_to '/video/latest'
  end



  def destroy
  end

end
