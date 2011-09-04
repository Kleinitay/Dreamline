class Video < ActiveRecord::Base

belongs_to :user, :dependent => :destroy

def add_new_video(user_id,title)
  Video.create(:user_id => user_id, :title => title)
end
