class VideosController < ApplicationController
	
	def show_video
		
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
  
  
end
