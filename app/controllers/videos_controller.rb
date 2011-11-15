class VideosController < ApplicationController

 before_filter :redirect_first_page_to_base
	
	def show
		video_id = params[:id].to_i
		@video = Video.for_view(video_id) if video_id != 0
		if !@video then render_404 and return end
	  check_video_redirection(@video)
	  @user = @video.user
	  @own_videos = current_user == @user ? true : false
	  @comments, @total_comments_count = Comment.get_video_comments(video_id)

	  #sidebar
	  get_sidebar_data # latest
	  @user_videos = Video.get_videos_by_user(1, @user.id, true, 3)
	  @trending_videos = Video.get_videos_by_sort(1,"popular", true ,3)
	  @active_users = User.get_users_by_activity
	end
	
	def list
	  @videos = []
	  @order = params[:order]
	  current_page = (params[:page] == "0" ? "1" : params[:page]).to_i
	  case
      when @order == "most popular" || @order == "latest"
        @videos = Video.get_videos_by_sort(current_page, @order, false)
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
    @sidebar_videos = Video.get_videos_by_sort(1,@sidebar_order, true ,3)
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
         @video.detect_and_convert
        flash[:notice] = "Video has been uploaded"
        redirect_to "/video/#{@video.id}/edit_tags"
      else
        render 'new'
      end
    else
      redirect_to "/"
    end
  end

  def edit
     @video = Video.find(params[:id])
  end

  def edit_tags
    @video = Video.find(params[:id])
    @taggees = @video.video_taggees
    @friends = fb_graph.get_connections(current_user.fb_id,'friends')
    #@likes = graph.get_connections("me", "likes")
  end

  def update
    unless !signed_in? || !params[:video]
      params[:video][:existing_taggee_attributes] ||= { }
      @video = Video.find(params[:id])
      if @video.update_attributes(params[:video])
        flash[:notice] = 'Tags saved'
        redirect_to video_path (@video)
      else
        flash[:notice] = 'Tags not saved'
        redirect_to video_path (@video)
      end
    else
      redirect_to "/"
    end
  end
end
