class Video < ActiveRecord::Base

  belongs_to :user,     :dependent => :destroy
  has_many   :comments, :dependent => :destroy
  #has_permalink :title, :as => :uri, :update => true
  # Check Why doesn't work??
  
  VIDEO_PATH = "/videos/"
  DEFAULT_IMG_PATH = "#{VIDEO_PATH}default_img/"
  CATEGORIES = CommonData[:video_categories]
  MAIN_LIST_LIMIT = 10
  
  def add_new_video(user_id,title)
    Video.create(:user_id => user_id, :title => title)
  end

  def uri
   "/video/#{id}-#{PermalinkFu.escape(title)}"
  end
  
  def category_uri()
    "/video/#{category_tag}"
  end

  def category_tag
    CATEGORIES[category]
  end

  def category_title
    category_tag.titleize
  end
  
  def self.directory(video_id)
   string_id = (video_id.to_s).rjust(9,"0")
   "#{VIDEO_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}" 
  end

  def thumb_src
    thumb = "#{Video.directory(id)}/thumbnail.jpg"
    FileTest.exists?("#{RAILS_ROOT}/public/#{thumb}") ? thumb : "#{DEFAULT_IMG_PATH}thumbnail.jpg"
  end
  
  def thumb_small_src
    thumb = "#{Video.directory(id)}/thumbnail_small.jpg"
    FileTest.exists?("#{RAILS_ROOT}/public/#{thumb}") ? thumb : "#{DEFAULT_IMG_PATH}thumbnail_small.jpg"
  end
  
  def self.for_view(id)
    video = Video.find(id)
    video[:category_title] = video.category_title 
    video
  end

# Moozly: the functions gets videos for showing in a list by sort order - latest or most popular  
  def self.get_videos_by_sort(order_by, sidebar, limit = MAIN_LIST_LIMIT)
    sort = order_by == "latest" ? "created_at" : "views_count"  
    vs = Video.all(:limit => limit, :order => sort + " desc")
    populate_videos_with_common_data(vs, sidebar, true) if vs
  end

# Moozly: the functions gets videos for showing in a list by the video category
 def self.get_videos_by_category(category_id)
   vs = Video.find(:all, :conditions => {:category => category_id}, :order => "created_at desc", :limit => 10)
   populate_videos_with_common_data(vs, false) if vs
 end

 def self.get_videos_by_user(user_id)
  vs = Video.find(:all, :conditions => {:user_id => user_id}, :limit => 10, :order => "created_at desc")
  if vs
    vs.each do |v|
      v[:thumb] = v.thumb_src
      v[:src] = "#{directory(v.id)}/#{v.id}.avi"
      v[:category_title] = v.category_title
    end
  end
 end

 def self.populate_videos_with_common_data(vs, sidebar, name = false)
   vs.each do |v|
     user = v.user
     v[:user_id] = user.id
     v[:user_nick] = user.nick
     v[:thumb] = sidebar ? v.thumb_small_src : v.thumb_src
     v[:src] = "#{directory(v.id)}/#{v.id}.avi"
     v[:category_title] = v.category_title if name
   end
 end

end