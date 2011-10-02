require "rexml/document"
module XMLParser
    #reads a faces xml file and outputs an array of images paths
    # @param filename [Object]
    def get_face_images(filename)
        retval = []
        doc = Document.new File.new(filename)
        doc.elements.each(("face")) do |face|
            retval << face.attributes["path"]
        end
        retval
    end
end
