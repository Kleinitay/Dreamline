class TimeSegment < ActiveRecord::Base
    belongs_to :video_taggee, :dependent => :destroy
end
