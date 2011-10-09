# == Schema Information
#
# Table name: video_taggees
#
#  id         :integer(4)      not null, primary key
#  contact_id :string(255)     not null
#  video_id   :string(255)     not null
#  created_at :datetime
#

class VideoTaggee < ActiveRecord::Base
    attr_accessible :id, :video_id, :contact_id

    belongs_to :video  , :dependent => :destroy
    has_many :time_segments


    def get_img_path
        vid = video.find(video_id)
        File.join("videos", "#{video.directory(vid.id)}", "images", id.to_s)
    end
end
