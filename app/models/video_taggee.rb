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
    belongs_to :video
    attr_accessor :should_destroy

    def edit
        @taggee = VideoTaggee.find(params[:id])
    end

    def img_path
        tmp = File.join(Video.directory_for_img(video_id), "faces","#{ id.to_s}.tif")
        tmp
    end
end
