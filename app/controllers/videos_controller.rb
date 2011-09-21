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
        @videos = Video.get_videos_by_sort(@order)
	    when Video::CATEGORIES.values.include?(@order)
	      @videos = Video.get_videos_by_category(@order)
	    else
	      render_404 and return
    end
  end

  def check_video_redirection(video)
    if request.path != video.uri
      redirect_to(request.request_uri.sub(request.path, video.uri), :status => 301)
    end  
  end  
  
end
