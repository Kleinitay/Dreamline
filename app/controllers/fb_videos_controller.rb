class FbVideosController < ApplicationController

 before_filter :authorize, :only => [:edit, :edit_tags]
	
	def show
		video_fb_id = params[:fb_id].to_i
		@video = Video.for_fb_view(video_fb_id) if video_fb_id != 0
		if !@video then render_404 and return end
	  check_video_redirection(@video)
	  @user = @video.user
	  @own_videos = current_user == @user ? true : false
	  @comments, @total_comments_count = Comment.get_video_comments(@video.id)
	  #sidebar
	  #get_sidebar_data # latest
	  #@user_videos = Video.get_videos_by_user(1, @user.id, true, 3)
	  #@trending_videos = Video.get_videos_by_sort(1,"popular", true ,3)
	  #@active_users = User.get_users_by_activity
	end
	
	def list
    @page_title = "Videos List"
    @videos = fb_graph.get_connections(current_user.fb_id,'videos/uploaded')
    app_fb_ids = Video.all(:conditions => {:user_id => current_user.id}, :select => "fbid").map(&:fbid)
    @videos.each do |v|
      v["analayzed"] = (app_fb_ids.include? v["id"]) ? true : false
      v["button_title"] = v["analayzed"] ? "Edit Tags" : "Vtag this video"
      v["href_part"] = "/fb/#{v['id']}/#{v['analayzed'] ? 'edit_tags' : 'analyze'}"
    end
    #get_sidebar_data

  end
  
  def vtaggees
    @page_title = "I got Vtagged"
    user = current_user
    @videos = Video.find_all_by_vtagged_user(645113644)#user.fb_id)
  end

  def check_video_redirection(video)
    if request.path != video.fb_uri
      redirect_to(request.request_uri.sub(request.path, video.fb_uri), :status => 301)
    end
  end

#  def get_sidebar_data
#    if @order == "latest"
#      @sidebar_order = "most popular"
#      @sidebar_list_title = "Trending Now"
#    else
#      @sidebar_order = "latest"
#      @sidebar_list_title = "Latest Ones"
#    end
#    @sidebar_videos = Video.get_videos_by_sort(1,@sidebar_order, true ,3)
#    @active_users = User.get_users_by_activity
#  end

  def new
    @video = Video.new
  end

  def create
    unless !params[:video]
       more_params = {:user_id => current_user.id, :duration => 0} #temp duration
       @video = Video.new(params[:video].merge(more_params))
       if @video.save
         @video.detect_and_convert(fb_graph,fb_access_token)
         flash[:notice] = "Video has been uploaded"
         redirect_to "/fb/#{@video.fbid}/edit_tags/new"
       else
         render 'new'
       end
     else
       redirect_to "/fb/list"#????
     end
  end

  def edit
    @video = Video.find_by_fbid(params[:fb_id])
  end

  def analyze
    v = fb_graph.get_object(params[:fb_id])
    params = {:user_id => current_user.id,
              :fbid => v["id"],
              :duration => 0, 
              :title => v["name"],
              :category => 20
             }
    @video = Video.new(params)
    if @video.save
      @video.detect_and_convert(fb_graph,fb_access_token)
      flash[:notice] = "Video has been uploaded"
      redirect_to "/fb/#{@video.fbid}/edit_tags/new"
    else
      render :text => @video.errors
    end
  end

  def edit_tags
    #begin
      @new = request.path.index("/new") ? true : false
      @video = Video.find_by_fbid(params[:fb_id])
      if @video.title.nil?
        @video.title = ""
      end
      @page_title = "#{@video.title.titleize} - #{@new ? "Add Tags" : "Edit"} Tags"
      @user = current_user
      @taggees = @video.video_taggees
      friends = fb_graph.get_connections(current_user.fb_id,'friends')
      @friends = {"#{current_user.nick}" => "#{current_user.fb_id }"}
      friends.map {|friend| @friends[friend["name"]] = friend["id"]}
      @names_arr = @friends.keys
      #@likes = graph.get_connections("me", "likes")

      #sidebar
  	  #get_sidebar_data # latest
  	  #@user_videos = Video.get_videos_by_user(1, @user.id, true, 3)
  	  #@trending_videos = Video.get_videos_by_sort(1,"popular", true ,3)
  	  #@active_users = User.get_users_by_activity
  
    #rescue Exception=>e
    #render :text => "Session Has gone away. Please refresh and login again."
    #sign_out
    #end
  end
 
  def update
    unless !signed_in? || !params[:video]
      @video = Video.find_by_fbid(params[:fb_id])
      @new = request.path.index("/new") ? true : false
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
        redirect_to @video.fb_uri
      end# if update_attributes
    else
      redirect_to "/fb/list"
    end
  end

end
