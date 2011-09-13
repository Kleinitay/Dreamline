class Video < ActiveRecord::Base

  belongs_to :user, :dependent => :destroy
  #has_permalink :title, :as => :uri, :update => true
  # Check Why doesn't work??
  
  VIDEO_PATH = "/videos/"
  
  def add_new_video(user_id,title)
    Video.create(:user_id => user_id, :title => title)
  end

  def uri
   "/video/#{id}-#{PermalinkFu.escape(title)}"
  end

  def self.directory(video_id)
   string_id = (video_id.to_s).rjust(9,"0")
   "#{VIDEO_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}" 
  end

end