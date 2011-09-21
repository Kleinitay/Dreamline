class User < ActiveRecord::Base
  belongs_to :user, :dependent => :destroy
  belongs_to :video, :dependent => :destroy
end