class VideosController < ApplicationController
	
	def show_video
		video_id = params[:id].to_i
		@video = Video.find(video_id) if video_id != 0
		if !@video then render_404 and return end
	  check_video_redirection(@video)
	  @user = @video.user
	end
	
	def list
	  if params[:order] == "popular"
	    @order = "most popular"
	    @videos = Video.get_by_popular
	  else
      @order = "latest"
	    @videos = Video.get_latest
   end
  end

  def check_video_redirection(video)
    if request.path != video.uri
      redirect_to(request.request_uri.sub(request.path, video.uri), :status => 301)
    end  
  end  
  
end
