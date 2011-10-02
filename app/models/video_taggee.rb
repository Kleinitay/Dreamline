# == Schema Information
#
# Table name: video_taggees
#
#  id         :integer(4)      not null, primary key
#  contact_id :string(255)     not null
#  video_id   :string(255)     not null
#  video_time :datetime        not null
#  created_at :datetime
#

class VideoTaggee < ActiveRecord::Base
    belongs_to :video

end
