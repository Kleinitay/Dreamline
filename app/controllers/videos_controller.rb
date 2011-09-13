class VideosController < ApplicationController
	
	def show_video
		video_id = params[:id].to_i
		@video = Video.find(video_id) if video_id != 0
		if !@video then render_404 and return end
	  check_video_redirection(@video)
	end
	
	def list
	  #Moozly: add support in:
#	  if params[:order] == "popular"
#	    @order = "most popular"
#	    @videos = get_videos_by_popular  
#	  else
#	    @order = "latest"
#	    @videos = get_videos_by_latest
#   end
	  #in the meantime:
	  @order = "latest"
	  @videos = []
  end


  def check_video_redirection(video)
    if request.path != video.uri
      redirect_to(request.request_uri.sub(request.path, video.uri), :status => 301)
    end  
  end  
  
end
