class User < ActiveRecord::Base
  include Clearance::User
  
  has_many :videos
  has_many :comments
  
  IMAGES_PATH = '/images/user_images/'
  
  def self.directory(user_id)
    string_id = (user_id.to_s).rjust(9,"0")
    "#{IMAGES_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}"
  end
  
end
