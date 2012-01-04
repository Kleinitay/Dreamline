class FbVideosController < ApplicationController

 before_filter :parse_facebook_cookies, :authorize, :only => [:edit, :edit_tags]
	
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
	  current_page = (params[:page] == "0" ? "1" : params[:page]).to_i
    @page_title = "Videos List"
    @videos = fb_graph.get_connections(current_user.fb_id,'videos/uploaded')
    #get_sidebar_data

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
        redirect_to "/video/#{@video.id}/edit_tags/new"
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
    begin
      @new = params[:new]=="new" ? true : false
      @video = Video.find(params[:id])
      @page_title = "#{@video.title.titleize} - #{@new ? "Add Tags" : "Edit"} Tags"
      @user = current_user
      @taggees = @video.video_taggees
      friends = fb_graph.get_connections(current_user.fb_id,'friends')
      @friends = {}
      friends.map {|friend| @friends[friend["name"]] = friend["id"]}
      @names_arr = @friends.keys
      #@likes = graph.get_connections("me", "likes")

      #sidebar
  	  get_sidebar_data # latest
  	  @user_videos = Video.get_videos_by_user(1, @user.id, true, 3)
  	  @trending_videos = Video.get_videos_by_sort(1,"popular", true ,3)
  	  @active_users = User.get_users_by_activity
  
    rescue Exception=>e
    render :text => "Session Has gone away. Please refresh and login again."
    sign_out
    end
  end
 
  def update
    unless !signed_in? || !params[:video]
      @video = Video.find(params[:id])
      @new = params[:new]=="new" ? true : false
      existing_taggees = @video.video_taggees_uniq.map(&:fb_id)
      updated_taggees_ids = []
      updated_taggees_ids = params[:video][:existing_taggee_attributes].values.map!{|h| h["fb_id"].to_i}.uniq.reject{ |id| id==0 } 
      if @video.update_attributes(params[:video])
        if updated_taggees_ids.any?
          if @new
            new_taggees = updated_taggees_ids
          else     
            new_taggees = (updated_taggees_ids - existing_taggees)
          end
          post_vtag(@new, new_taggees, @video.title.titleize)
        end #if ids
        redirect_to video_path (@video)
      end# if update_attributes
    else
      redirect_to "/"
    end
  end
end
