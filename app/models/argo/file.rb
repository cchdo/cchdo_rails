# ARGO_ROOT is set in config/environment.rb
# The real files are stored in ARGO_ROOT/files.
# The expocode directories contain files that are linked to the real files to
# provide filesystem "management" for those opposed to web interfaces.


class Argo::File < ActiveRecord::Base
    FILES_DIR = 'files'
    ABS_ARGO_ROOT = Rails.root.join(ARGO_ROOT)
    REAL_DIR = File.join(ABS_ARGO_ROOT, FILES_DIR)

    set_table_name 'argo_files'

    validates_presence_of :filename

    has_attachment :storage => :file_system,
                   :partition => false,
                   :path_prefix => ::File.join(ARGO_ROOT, FILES_DIR)

    belongs_to :user
    has_many :downloads, :class_name => 'Argo::Download'

    after_save :link_expocode_dir
    after_destroy :unlink_expocode_dir

    def get_expocode_dir
        ::File.join(ABS_ARGO_ROOT, self.ExpoCode.gsub(/\W/, ''))
    end

    def link_expocode_dir
        expocode_dir = get_expocode_dir
        FileUtils.mkdir_p(expocode_dir)
        FileUtils.ln_s(::File.join(REAL_DIR, self.filename), ::File.join(expocode_dir, self.filename))
    end

    def unlink_expocode_dir
        expocode_dir = get_expocode_dir
        expocode_file = ::File.join(expocode_dir, self.filename)
        if ::File.symlink?(expocode_file)
            ::File.unlink(expocode_file)
            if (Dir.entries(expocode_dir) - ['.', '..']).empty?
                Dir.delete(expocode_dir)
            end
        end
    end
end


# Ensure Argo directories exist
FileUtils.mkdir_p(Argo::File::REAL_DIR)
