# == Schema Information
#
# Table name: comments
#
#  id         :integer(4)      not null, primary key
#  content    :text
#  video_id   :integer(4)      not null
#  user_id    :integer(4)      not null
#  status     :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

class Comment < ActiveRecord::Base
  belongs_to :user, :dependent => :destroy
  belongs_to :video, :dependent => :destroy

  def self.get_user_comments(user_id)
    Comment.all(:user_id => user_id, :limit => 10)
  end
end
