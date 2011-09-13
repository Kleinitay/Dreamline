class Video < ActiveRecord::Base

  belongs_to :user, :dependent => :destroy
  #has_permalink :title, :as => :uri, :update => true
  # Check Why doesn't work??
  def add_new_video(user_id,title)
    Video.create(:user_id => user_id, :title => title)
  end

  def uri
   "/video/#{id}-#{PermalinkFu.escape(title)}"
  end

end