class VideosController < ApplicationController
	
	def show_video
		video_id = params[:id].to_i
		@video = Video.for_view(video_id) if video_id != 0
		if !@video then render_404 and return end
	  check_video_redirection(@video)
	  @user = @video.user

	  #sidebar
	  get_sidebar_data # latest
	  @user_videos = Video.get_videos_by_user(@user.id, true, 3)
	  @trending_videos = Video.get_videos_by_sort("popular", true ,3)
	  @active_users = User.get_users_by_activity
	end
	
	def list
	  @videos = []
	  @order = params[:order]
	  case
      when @order == "most popular" || @order == "latest"
        @videos = Video.get_videos_by_sort(@order, false)
	    when key = Video::CATEGORIES.key(@order)
	      @videos = Video.get_videos_by_category(key)
	      @category = true
	    else
	      render_404 and return
    end
    @page_title = @order.titleize
    get_sidebar_data

  end

  def check_video_redirection(video)
    if request.path != video.uri
      redirect_to(request.request_uri.sub(request.path, video.uri), :status => 301)
    end  
  end

  def get_sidebar_data
    if @order == "latest"
      @sidebar_order = "most popular"
      @sidebar_list_title = "Trending Now"
    else
      @sidebar_order = "latest"
      @sidebar_list_title = "Latest Ones"
    end
    @sidebar_videos = Video.get_videos_by_sort(@sidebar_order, true ,3)
    @active_users = User.get_users_by_activity
  end

  def new
    @video = Video.new
  end

  def create
    unless !signed_in? || !params[:video]
      more_params = {:user_id => current_user.id, :duration => 0} #temp duration
      @video = Video.new(params[:video].merge(more_params))
      if @video.save
        @video.convert_to_flv
        flash[:notice] = 'Video has been uploaded'
        redirect_to @video.uri
      else
        render 'new'
      end
    else
      redirect_to "/"
    end
  end
end
