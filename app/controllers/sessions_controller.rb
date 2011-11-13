class SessionsController < ApplicationController
  unloadable

  skip_before_filter :authorize, :only => [:new, :create, :destroy]
  #protect_from_forgery :except => :create

  def create
    @user = authenticate(params)
    if @user.nil?
      flash_failure_after_create
      render :template => 'users/sessions/new', :status => :unauthorized
    else
      sign_in(@user)
      redirect_back_or(url_after_create)
    end
  end

  def destroy
    sign_out
    begin
      fb_id = fb_oauth.get_user_from_cookies(cookies)
      url = fb_id ? fb_logout_url : url_after_destroy
    rescue
      render :text => "Session Has gone away. Please refresh and try again."
    end  
    #url = url_after_destroy
    redirect_to(url)
  end

  private

  def flash_failure_after_create
    flash.now[:notice] = translate(:bad_email_or_password,
      :scope   => [:clearance, :controllers, :sessions],
      :default => "Bad email or password.")
  end

  def url_after_create
    '/'
  end

  def url_after_destroy
    sign_in_url
  end
end