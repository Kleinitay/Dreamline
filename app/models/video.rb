class Video < ActiveRecord::Base

  belongs_to :user, :dependent => :destroy
  has_permalink :title, :update => true

  def add_new_video(user_id,title)
    Video.create(:user_id => user_id, :title => title)
  end

  def self.uri(id,title)
    "/video/#{id}-#{PermalinkFu.escape(title)}"
  end

end