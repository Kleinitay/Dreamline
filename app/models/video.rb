class Video < ActiveRecord::Base

  belongs_to :user,     :dependent => :destroy
  has_many   :comments, :dependent => :destroy
  #has_permalink :title, :as => :uri, :update => true
  # Check Why doesn't work??
  
  VIDEO_PATH = "/videos/"
  CATEGORIES = CommonData[:video_categories]
  
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

  def self.for_view(id)
    video = Video.find(id)
    video[:category_title] = video.category_title 
    video
  end

# Moozly: the functions gets videos for showing in a list by sort order - latest or most popular  
  def self.get_videos_by_sort(order_by)
    sort = order_by == "latest" ? "created_at" : "views_count"  
    vs = Video.all(:limit => 10, :order => sort + " desc")
    populate_videos_with_common_data(vs, true) if vs
  end

# Moozly: the functions gets videos for showing in a list by the video category
 def self.get_videos_by_category(category_id)
   vs = Video.find(:all, :conditions => {:category => category_id}, :order => "created_at desc", :limit => 10)
   populate_videos_with_common_data(vs) if vs
 end


 def self.populate_videos_with_common_data(vs, name = false)
   vs.each do |v|
     puts v.user
     user = v.user
     v[:user_id] = user.id
     v[:user_nick] = user.nick
     v[:thumb] = "#{directory(v.id)}/thumbnail.jpg"
     v[:src] = "#{directory(v.id)}/#{v.id}.avi"
     v[:category_title] = v.category_title if name
   end
 end





end