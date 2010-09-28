# ARGO_ROOT is set in config/environment.rb
# The real files are stored in ARGO_ROOT/files.
# The expocode directories contain files that are linked to the real files to
# provide filesystem "management" for those opposed to web interfaces.


class Argo::File < ActiveRecord::Base
    FILES_DIR = 'files'
    ABS_ARGO_ROOT = Rails.root.join(ARGO_ROOT)
    REAL_DIR = File.join(ABS_ARGO_ROOT, FILES_DIR)

    set_table_name 'argo_files'

    validates_presence_of :ExpoCode
    validates_presence_of :filename

    has_attachment :storage => :file_system,
                   :partition => false,
                   :path_prefix => ::File.join(ARGO_ROOT, FILES_DIR)

    belongs_to :user
    has_many :downloads, :class_name => 'Argo::Download'

    after_create :link_in_expocode_dir
    after_destroy :unlink_from_expocode_dir

    def get_expocode_dir
        if self.ExpoCode
            ::File.join(ABS_ARGO_ROOT, self.ExpoCode.gsub(/\W/, ''))
        else
            nil
        end
    end

    def link_in_expocode_dir
        if expocode_dir = get_expocode_dir() and self.filename
            FileUtils.mkdir_p(expocode_dir)
            link = ::File.join(expocode_dir, self.filename)
            if ::File.symlink?(link)
                ::File.unlink(link)
	    end
            FileUtils.ln_s(::File.join(REAL_DIR, self.filename), link)
        end
    end

    def unlink_from_expocode_dir
        if expocode_dir = get_expocode_dir() and self.filename
            expocode_file = ::File.join(expocode_dir, self.filename)
            if ::File.symlink?(expocode_file)
                ::File.unlink(expocode_file)
                if (Dir.entries(expocode_dir) - ['.', '..']).empty?
                    Dir.delete(expocode_dir)
                end
            end
        end
    end

    def ExpoCode=(expocode)
    	# Do extra linking and unlinking if editing a file.
        unless self.ExpoCode.blank? and not self.filename
            if expocode != self.ExpoCode
                unlink_from_expocode_dir()
	    end
            self[:ExpoCode] = expocode
            link_in_expocode_dir()
	else
            self[:ExpoCode] = expocode
        end
    end
end


# Ensure Argo directories exist
begin
    FileUtils.mkdir_p(Argo::File::REAL_DIR)
rescue => e
    raise "Unable to create directory structure for Argo File repository.\n" + 
          "Please create public/data/argo/files with permissions read-writeable by " +
          "the webserver."
end
