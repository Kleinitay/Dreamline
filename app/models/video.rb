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
require "rexml/document"
class Video < ActiveRecord::Base

  belongs_to :user

  has_many :comments, :dependent => :destroy
  has_many :video_taggees, :dependent => :destroy


  has_many :comments
  has_many :video_taggees

  # has_permalink :title, :as => :uri, :update => true
  # Check Why doesn't work??

  # Paperclip
  # http://www.thoughtbot.com/projects/paperclip
  has_attached_file :source, :url => :path_for_origion

  # Paperclip Validations
  validates_attachment_presence :source
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
  FULL_VIDEO_PATH = "#{RAILS_ROOT}/public/videos/"
  CATEGORIES = CommonData[:video_categories]
  MAIN_LIST_LIMIT = 10

  FACE_RESULTS = "faces.xml"
  FACES_DIR = "faces"

#------------------------------------------------------ Instance methods -------------------------------------------------------
  def add_new_video(user_id, title)
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
      string_id = (id.to_s).rjust(9, "0")
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


# run process
    def detect_and_convert
        if convert_to_flv
            detect_face_and_timestamps
        else
            false
        end
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
      File.join(dirname, "#{id}.flv")
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
  def self.uri(id)
    v=Video.find_by_id(id,:select => 'title')
    "/video/#{id}-#{PermalinkFu.escape(v.title)}"
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

  def detect_face_and_timestamps
    create_faces_directory
    cmd = detect_command
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

  def detect_command
    output_dir = faces_directory
    input_file = File.join(Video.full_directory(id),id.to_s)
    "MovieFaceRecognition Dreamline #{input_file} #{output_dir}"
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
      taggee.contact_id =  ""
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
                video_taggees.delete(taggee)
            end
        end
    end

    def save_taggees
        video_taggees.each do |t|
            t.save(false)
        end
    end
    #___________________________________________taggees handling______________________
end

