# == Schema Information
#
# Table name: users
#
#  id                 :integer(4)      not null, primary key
#  email              :string(255)     not null
#  password           :string(255)
#  nick               :string(255)
#  fb_id              :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  encrypted_password :string(128)
#  salt               :string(128)
#  confirmation_token :string(128)
#  remember_token     :string(128)
#  status             :integer(4)      not null
#

class User < ActiveRecord::Base
  include Clearance::User
  
  has_many :videos
  has_many :comments

#--------------------- Global params --------------------------
  IMAGES_PATH = '/images/user_images/'


#------------------------------------------------------ Instance methods -------------------------------------------------------




#------------------------------------------------------ Class methods -------------------------------------------------------
  def self.directory(user_id)
    string_id = (user_id.to_s).rjust(9,"0")
    "#{IMAGES_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}"
  end
  
end
