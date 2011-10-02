# == Schema Information
#
# Table name: videos
#
#  id                  :integer(4)      not null, primary key
#  user_id             :integer(4)      not null
#  title               :string(255)
#  views_count         :integer(4)      default(0)
#  created_at          :datetime
#  updated_at          :datetime
#  duration            :integer(4)      not null
#  category            :integer(4)      not null
#  description         :string(255)
#  keywords            :string(255)
#  source_content_type :string(255)
#  source_file_name    :string(255)
#  source_file_size    :integer(4)
#  state               :string(255)
#

class Video < ActiveRecord::Base

  belongs_to :user,     :dependent => :destroy
  has_many   :comments, :dependent => :destroy
  has_many   :video_taggeeses, :dependent => :destroy
  # has_permalink :title, :as => :uri, :update => true
  # Check Why doesn't work??

  # Paperclip
  # http://www.thoughtbot.com/projects/paperclip
  has_attached_file :source , :url => :path_for_origion

  # Paperclip Validations
  validates_attachment_presence :source
  validates_attachment_content_type :source, :content_type => 'video/quicktime'


  # Acts as State Machine
  # http://elitists.textdriven.com/svn/plugins/acts_as_state_machine
  acts_as_state_machine :initial => :pending
  state :pending
  state :analysing
  state :analysed
  state :converting
  state :converted, :enter => :set_new_filename
  state :error

  event :convert_to_flv do
    transitions :from => :pending, :to => :converting
    transitions :from => :analysed, :to => :converting
  end

  event :converted do
    transitions :from => :converting, :to => :converted
  end

  event :failed do
    transitions :from => :converting, :to => :error
  end

  event :analyse do
    transitions :from => :pending, :to => :analysing
  end

  event :analysed do
    transitions :from => :analysing, :to => :analysed
  end



#--------------------- Global params --------------------------
  IMG_VIDEO_PATH = "/videos/"
  DEFAULT_IMG_PATH = "#{IMG_VIDEO_PATH}default_img/"
  FULL_VIDEO_PATH = "#{RAILS_ROOT}/public/videos/"
  CATEGORIES = CommonData[:video_categories]
  MAIN_LIST_LIMIT = 10
  
  FACE_RESULTS = "faces.xml"
  FACES_DIR = "faces"

#------------------------------------------------------ Instance methods -------------------------------------------------------
  def add_new_video(user_id,title)
    Video.create(:user_id => user_id, :title => title)
  end

  def uri
   "/video/#{id}-#{PermalinkFu.escape(title)}"
  end
  
  def category_uri()
    "/video/#{category_tag}"
  end

  def category_tag
    CATEGORIES[category]
  end

  def category_title
    category_tag.titleize
  end
  
  # Moozly: path for saving temp origion uploaded video
  def path_for_origion
   string_id = (id.to_s).rjust(9,"0")
   "#{IMG_VIDEO_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}/#{id}" 
  end

  def thumb_src
    thumb = "#{Video.directory_for_img(id)}/thumbnail.jpg"
    FileTest.exists?("#{RAILS_ROOT}/public/#{thumb}") ? thumb : "#{DEFAULT_IMG_PATH}thumbnail.jpg"
  end
  
  def thumb_small_src
    thumb = "#{Video.directory_for_img(id)}/thumbnail_small.jpg"
    FileTest.exists?("#{RAILS_ROOT}/public/#{thumb}") ? thumb : "#{DEFAULT_IMG_PATH}thumbnail_small.jpg"
  end

# _____________________________________________ FLV conversion functions _______________________

  def convert_to_flv
    self.convert_to_flv!
    success = system(convert_command)
    if success && $?.exitstatus == 0
      self.converted!
    else
      self.failed!
    end
  end

  def set_new_filename
    update_attribute(:source_file_name, "#{id}.flv")
  end

  def get_flv_file_name
    dirname = Video.full_directory(id)
    File.join(dirname, "#{id}.flv" )
  end
  
  def convert_command
    output_file = self.get_flv_file_name
    File.open(output_file, 'w')
    command = <<-end_command
      ffmpeg -i #{ source.path } -ar 22050 -ab 32 -acodec libmp3lame -s 480x360 -vcodec flv -r 25 -qscale 8 -f flv -y #{ output_file }
    end_command
    command.gsub!(/\s+/, " ")
  end
# _____________________________________________ FLV conversion functions _______________________


  
#------------------------------------------------------ Class methods -------------------------------------------------------

  def self.directory_for_img(video_id)
   string_id = (video_id.to_s).rjust(9,"0")
   "#{IMG_VIDEO_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}"
  end

  def self.full_directory(video_id)
   string_id = (video_id.to_s).rjust(9,"0")
   "#{FULL_VIDEO_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}"
  end

  def self.for_view(id)
    video = Video.find(id)
    video[:category_title] = video.category_title 
    video
  end

# Moozly: the functions gets videos for showing in a list by sort order - latest or most popular  
  def self.get_videos_by_sort(order_by, sidebar, limit = MAIN_LIST_LIMIT)
    sort = order_by == "latest" ? "created_at" : "views_count"  
    vs = Video.all(:limit => limit, :order => sort + " desc")
    populate_videos_with_common_data(vs, sidebar, true) if vs
  end

# Moozly: the functions gets videos for showing in a list by the video category
 def self.get_videos_by_category(category_id)
   vs = Video.find(:all, :conditions => {:category => category_id}, :order => "created_at desc", :limit => 10)
   populate_videos_with_common_data(vs, false) if vs
 end

 def self.get_videos_by_user(user_id)
  vs = Video.find(:all, :conditions => {:user_id => user_id}, :limit => 10, :order => "created_at desc")
  if vs
    vs.each do |v|
      v[:thumb] = v.thumb_src
      v[:src] = "#{directory_for_img(v.id)}/#{v.id}.avi"
      v[:category_title] = v.category_title
    end
  end
 end

 def self.populate_videos_with_common_data(vs, sidebar, name = false)
   vs.each do |v|
     user = v.user
     v[:user_id] = user.id
     v[:user_nick] = user.nick
     v[:thumb] = sidebar ? v.thumb_small_src : v.thumb_src
     v[:src] = "#{directory_for_img(v.id)}/#{v.id}.avi"
     v[:category_title] = v.category_title if name
   end
 end
 
# _____________________________________________ Face detection _______________________

  def self.detect_face_and_timestamps
    success = system(convert_command)
    if success && $?.exitstatus == 0
      self.analyzed!
    else
      self.failure!
    end
  end

  def self.get_avi_file_name
    File.join(full_directory(:id),"#{id.to_s}.avi")
  end

  def self.get_timestamps_xml_file_name
    File.join(full_directory(:id),FACES_DIR,FACE_RESULTS)
  end

  def self.detect_command
     output_dir = File.join(full_directory(:id), FACES_DIR)
    "MovieFaceRecognition.exe Dreamline #{get_avi_file_name} #{output_dir}"
  end
# _____________________________________________ Face detection _______________________
end

