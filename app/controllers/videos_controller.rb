class VideosController < ApplicationController
	
	def show_video
		video_id = params[:id].to_i
		@video = Video.for_view(video_id) if video_id != 0
		if !@video then render_404 and return end
	  check_video_redirection(@video)
	  @user = @video.user
	end
	
	def list
	  @videos = []
	  @order = params[:order]
	  case
      when @order == "popular" || @order == "latest"
        @videos = Video.get_videos_by_sort(@order, false)
	    when key = Video::CATEGORIES.key(@order)
	      @videos = Video.get_videos_by_category(key)
	      @category = true
	    else
	      render_404 and return
    end
    @page_title = @order == "popular" ? "Most Popular" : @order.titleize
    get_sidebar_data

  end

  def check_video_redirection(video)
    if request.path != video.uri
      redirect_to(request.request_uri.sub(request.path, video.uri), :status => 301)
    end  
  end

  def get_sidebar_data
    if @order == "latest"
      @sidebar_order = "popular"
      @sidebar_list_title = "Trending Now"
    else
      @sidebar_order = "latest"
      @sidebar_list_title = "Latest Ones"
    end
    @sidebar_videos = Video.get_videos_by_sort(@sidebar_order, true ,3)
  end
  
end
