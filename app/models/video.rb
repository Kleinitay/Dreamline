# == Schema Information
#
# Table name: videos
#
#  id          :integer(4)      not null, primary key
#  user_id     :integer(4)      not null
#  title       :string(255)
#  views_count :integer(4)      default(0)
#  created_at  :datetime
#  updated_at  :datetime
#  duration    :integer(4)      not null
#  category    :integer(4)      not null
#  description :string(255)
#  keywords    :string(255)
#  state       :string(255)
#  fbid        :string(255)
#  analyzed    :boolean(1)
#  video_file  :string(255)
#

require "rexml/document"
require 'carrierwave/orm/activerecord'
class Video < ActiveRecord::Base

  belongs_to :user

  has_many :comments, :dependent => :destroy
  has_many :video_taggees, :dependent => :destroy


  has_many :comments

  mount_uploader :video_file, VideoFileUploader
  # has_permalink :title, :as => :uri, :update => true
  # Check Why doesn't work??

  # Paperclip
  # http://www.thoughtbot.com/projects/paperclip
  #has_attached_file :source, :url => :path_for_origin

  # Paperclip Validations
  #validates_attachment_presence :source
  #validates_attachment_content_type :source, :content_type => 'video'

  after_update :save_taggees
  # Acts as State Machine
  # http://elitists.textdriven.com/svn/plugins/acts_as_state_machine
  acts_as_state_machine :initial => :pending
  state :pending
  state :analysing
  state :analysed, :enter => :convert_to_flv
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

  event :analyse do
    transitions :from => :converted, :to => :analysing
    transitions :from => :pending, :to => :analysing
  end


#--------------------- Global params --------------------------
  IMG_VIDEO_PATH = "/videos/"
  DEFAULT_IMG_PATH = "#{IMG_VIDEO_PATH}default_img/"
  FULL_VIDEO_PATH = "#{Rails.root.to_s}/public/videos/"
  CATEGORIES = CommonData[:video_categories]
  MAIN_LIST_LIMIT = 10

  FACE_RESULTS = "faces.xml"
  FACES_DIR = "faces"
  MOVIE_FACE_RECOGNITION_EXEC_PATH = "#{Rails.root.to_s}/MovieFaceDetector/MovieFaceRecognition"
  HAAR_CASCADES_PATH = "#{Rails.root.to_s}/MovieFaceDetector/haarcascades/haarcascade_frontalface_alt_tree.xml"


#------------------------------------------------------ Instance methods -------------------------------------------------------
  def add_new_video(user_id, title)
    Video.create(:user_id => user_id, :title => title)
  end

  def uri
    "/video/#{id}-#{PermalinkFu.escape(title)}"
  end
  
  def fb_uri
    "fb/id/#{id}-#{PermalinkFu.escape(title)}"
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
  def path_for_origin
    string_id = (id.to_s).rjust(9, "0")
    "#{IMG_VIDEO_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}/#{id}"
  end

  def thumb_path
    File.join(Video.directory_for_img(id), "thumbnail.jpg")
  end

  def thumb_path_small
    File.join(Video.directory_for_img(id), "thumbnail_small.jpg")
  end

  def thumb_src
    thumb = thumb_path
    FileTest.exists?("#{Rails.root.to_s}/public/#{thumb}") ? thumb : "#{DEFAULT_IMG_PATH}thumbnail.jpg"
  end

  def thumb_small_src
    thumb = thumb_path_small
    FileTest.exists?("#{Rails.root.to_s}/public/#{thumb}") ? thumb : "#{DEFAULT_IMG_PATH}thumbnail_small.jpg"
  end


  # run algorithm process
  def detect_and_convert(graph,access_token)
    video_info = get_video_info
    unless video_info["Duration"].nil?
      dur = parse_duration_string video_info["Duration"]
      self.update_attribute(:duration, dur)
    end
    # fbid = "10150531862603645"
    if fbid != nil
      #do the analysis on the facebook link
      result = graph.get_object(fbid)
      source = result["source"]
      self.remote_video_file_url = source
      detect_face_and_timestamps video_file.current_path
    elsif access_token != nil &&  access_token != ""
      unless convert_to_flv  video_info
        return false
      end
      detect_face_and_timestamps get_flv_file_name
      result = graph.put_video(get_flv_file_name, {:title => self.title})
      self.update_attribute(:fbid, result["id"])
      #  File.delete(get_flv_file_name)
    else
      if convert_to_flv video_info
        detect_face_and_timestamps get_flv_file_name
      else
        false
      end
    end
  end

  def video_taggees_uniq
    VideoTaggee.find(:all, :select => "DISTINCT contact_info, fb_id", :conditions => {:video_id => self.id})
  end

  def parse_duration_string duration_str
    minstr = duration_str.slice(/[0-9]+mn/)
    unless minstr.nil?
      mins = minstr.slice(/[0-9]+/)
    end
    secstr = duration_str.slice(/[0-9]+s/)
    unless secstr.nil?
      secs = secstr.slice(/[0-9]+/)
    end
    mins.to_i*60+secs.to_i
  end
# _____________________________________________ FLV conversion functions _______________________

  def convert_to_flv  video_info
    self.convert_to_flv!
    success = system(convert_command video_info)
    if success && $?.exitstatus == 0
        self.converted!
    else
        self.failed!
    end
  end

  def set_new_filename
    #update_attribute(:source_file_name, "#{id}.flv")
    self.video_file = File.open(get_flv_file_name)
  end

  def get_flv_file_name
    dirname = Video.full_directory(id)
    File.join(dirname, "#{id}.flv")
  end

  def convert_command  video_info
    output_file = self.get_flv_file_name
    File.open(output_file, 'w')
    command = <<-end_command
    ffmpeg -i #{ video_file.current_path } #{get_video_rotation_cmd video_info['Rotation']} -ar 22050 -ab 32 -acodec libmp3lame -s 480x360 -vcodec flv -r 25 -qscale 8 -f flv -y #{ output_file }
    end_command
    command.gsub!(/\s+/, " ")
  end

  def get_video_info
    mediainfo_path = File.join( Rails.root, "Mediainfo", "Mediainfo")
    response =`mediainfo #{video_file.current_path} --output=xml 2>&1`
    if response == nil
      return
    end
    xml_hash = Hash.from_xml response
    xml_hash['Mediainfo']['File']['track'][1]
  end

  def get_video_rotation_cmd  degrees=nil
    #mediainfo_path = File.join( Rails.root, "Mediainfo", "Mediainfo")
    #response =`#{mediainfo_path} #{source.path} --output=json 2>&1`
    # response = response.gsub(/ /,'')
    if degrees.nil? || degrees == ""
                return ""
    elsif degrees[0,2] == "18"
        return "-vf transpose=3"
    elsif degrees[0,2] == "27"
        return "-vf transpose=1"
    elsif degrees[0,2] == "90"
        return "-vf transpose=0"
    else
        return ""
    end
  end
# _____________________________________________ FLV conversion functions _______________________


#------------------------------------------------------ Class methods -------------------------------------------------------
  def self.uri(id)
    v=Video.find_by_id(id,:select => 'title')
    "/video/#{id}-#{PermalinkFu.escape(v.title)}"
  end
  
  def self.fb_uri(id)
    v=Video.find_by_fbid(id,:select => 'title')
    v ? ("/fb/#{id}#{ v.title.empty? ? "" : "-" + PermalinkFu.escape(v.title)}") : "http://facebook.com/#{id}"
  end
  
  def self.directory_for_img(video_id)
    string_id = (video_id.to_s).rjust(9, "0")
    File.join("#{IMG_VIDEO_PATH}#{string_id[0..2]}","#{string_id[3..5]}","#{string_id[6..8]}" )
  end

  def self.full_directory(video_id)
    string_id = (video_id.to_s).rjust(9, "0")
    "#{FULL_VIDEO_PATH}#{string_id[0..2]}/#{string_id[3..5]}/#{string_id[6..8]}"
  end

  def self.for_view(id)
    video = Video.find(id)
    video[:category_title] = video.category_title
    video
  end

  def self.for_fb_view(id)
    video = Video.find_by_fbid(id)
    video[:category_title] = video.category_title
    video
  end

  # Moozly: the functions gets videos for showing in a list by sort order - latest or most popular  
  def self.get_videos_by_sort(page, order_by, sidebar, limit = MAIN_LIST_LIMIT)
    sort = order_by == "latest" ? "created_at" : "views_count"
    vs = Video.paginate(:page => page, :per_page => limit).order("#{sort } desc")
    populate_videos_with_common_data(vs, sidebar, true) if vs
  end

  # Moozly: the functions gets videos for showing in a list by the video category
  def self.get_videos_by_category(category_id)
   vs = Video.find(:all, :conditions => {:category => category_id}, :order => "created_at desc", :limit => 10)
   populate_videos_with_common_data(vs, false) if vs
  end

  def self.get_videos_by_user(page, user_id, sidebar, limit = MAIN_LIST_LIMIT)
    vs = Video.where(:user_id => user_id).paginate(:page => page, :per_page => limit).order("created_at desc")
    if vs.any?
      user_nick = vs.first.user.nick
      vs.each do |v|
        v[:thumb] = sidebar ? v.thumb_small_src : v.thumb_src
        v[:src] = "#{directory_for_img(v.id)}/#{v.id}.avi"
        v[:category_title] = v.category_title
        v[:user_nick] = user_nick
      end
    end
    vs
  end

 def self.find_all_by_vtagged_user(user_fbid)
   vs_ids = VideoTaggee.find_all_video_ids_by_user_id(user_fbid)
   @vs = vs_ids.any? ? self.where("id in (#{vs_ids.join(",")})") : []
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

  def detect_face_and_timestamps(filename)
    create_faces_directory
    cmd = detect_command filename
    logger.info cmd
    puts cmd
    success = system(cmd)
    if success && $?.exitstatus == 0
      parse_xml_add_tagees_and_timesegments(get_timestamps_xml_file_name)
      self.analysed!
    else
      self.failed!
    end
  end

  def get_avi_file_name
    File.join(Video.full_directory(:id), "#{id.to_s}.avi")
  end

  def get_timestamps_xml_file_name
    File.join(Video.full_directory(id), FACES_DIR, FACE_RESULTS)
  end

  def detect_command (filename)
    output_dir = faces_directory
    #input_file = File.join(Video.full_directory(id),id.to_s)
    input_file = filename
    if !File.exist?(input_file)
       input_file = video_file.current_path
    end

    "#{MOVIE_FACE_RECOGNITION_EXEC_PATH} Dreamline #{input_file} #{output_dir} #{HAAR_CASCADES_PATH} #{Rails.root.to_s}/public#{thumb_path} #{Rails.root.to_s}/public#{thumb_path_small}"
  end

  def faces_directory
    File.join(Video.full_directory(id), FACES_DIR)
  end

  def create_faces_directory
    Dir.mkdir(faces_directory)
  end

  def add_taggees
    VideoTaggee.new
  end

  def parse_xml_add_tagees_and_timesegments (filename)
    file = File.new(filename)
    doc = REXML::Document.new file
    doc.elements.each('//face') do |face|
      taggee = self.video_taggees.build
      taggee.contact_info =  ""
      taggee.save
      dir = File.dirname(face.attributes["path"])
      newFilename = File.join(dir, "#{taggee.id.to_s}.tif")
      File.rename(face.attributes["path"], newFilename)

      face.elements.each("timesegment ") do |segment|
        newSeg = TimeSegment.new
        newSeg.begin = segment.attributes["begin"].to_i
        newSeg.end = segment.attributes["end"].to_i
        newSeg.taggee_id = taggee.id
        newSeg.save
      end
    end
  end
# _____________________________________________ Face detection _______________________
    #___________________________________________taggees handling______________________
    def new_taggee_attributes=(taggee_attributes)
        taggee_attributes.each do |taggee|
            video_taggees.build(taggee)
        end
    end

    def existing_taggee_attributes=(taggee_attributes)
        video_taggees.reject(&:new_record?).each do |taggee|
            attributes = taggee_attributes[taggee.id.to_s]
            if attributes
                taggee.attributes = attributes
            else
                VideoTaggee.delete(taggee.id)
            end
        end
    end

    def save_taggees
      video_taggees.each do |t|
        t.save(false)
      end
    end
    #___________________________________________taggees handling______________________

    def test_facebook_video
      output_dir = faces_directory
      "#{MOVIE_FACE_RECOGNITION_EXEC_PATH} Dreamline https://fbcdn-video-a.akamaihd.net/cfs-ak-ash4/348369/702/10150436322608645_35460.mp4?oh=8e1db8c843f46df7b6d08693a0777387&oe=4EEB3C00&__gda__=1324039168_f09d0e23443449ae0c8365e36dab4e53 #{output_dir} #{HAAR_CASCADES_PATH} #{Rails.root.to_s}/public#{thumb_path} #{Rails.root.to_s}/public#{thumb_path_small}"
    end
end

