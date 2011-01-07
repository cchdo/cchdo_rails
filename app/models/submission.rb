require 'zip/zip'

class Submission < ActiveRecord::Base
    $submission_root = Rails.root.join('public', 'submissions')
    $allowed_actions = {
        :one => "Merge Data",
        :two => "Place Online",
        :three => "Updated Parameters",
        :four => "Non-public data for Argo calibration (proprietary, " + 
                 "rapid-delivery)"
    }
    $naming_lockfile = File.join($submission_root, '.naming.lck')
    MULTI_UPLOAD_FILE_NAME_BASE = 'multiple_files'

    validates_format_of :name,
                        :with => /^\w+.*$/,
                        :message => "Name is required"
 
    validates_format_of :institute,
                        :with => /^[\w\@\,\:\-\/_\s\.]+$/,
                        :message => "Institution name is required"
 
    validates_format_of :public,
                        :with => /^\w[a-zA-Z\s-]+$/,
                        :message => "*"
 
    validates_format_of :email,
                        :with => /^\w[\w\-\.]+\@[\w\-\.]+$/,
                        :message => "Email address is not formatted correctly"
 
    validates_each :file do |model, attr, value|
        model.errors.add(attr, "Please select a file that has data to " + 
                               "submit.") unless model.file_object_okay?(value)
    end

    before_save :fill_in_default_values, :save_file

    def action=(hash)
        # Figure out actions that were selected by client. Don't trust client
        # sent actions.
        actions = []
        hash = {} if hash.blank?
        $allowed_actions.each_pair do |number, action|
            if hash[number] == action
                actions << action
            else
                # TODO
                # This submission is likely forged because checkboxes should
                # always send what is expected.
            end
        end
        self[:action] = actions.join(', ')
    end

    class GeneratedTempfile < Tempfile
        attr_accessor :original_filename
        include ActionController::UploadedFile
        def initialize(filename)
          super(filename)
          @original_filename = filename
        end
        # XXX HACK allow reopening tempfiles. When able to write zip files to
        # IO stream, remove this.
        def reopen(path)
          @tmpname = path
          @data = [@tmpname]
          open()
        end
    end

    def files=(x)
        if x.is_a?(Hash)
            files = x.values()
            file_name = "#{MULTI_UPLOAD_FILE_NAME_BASE}.#{Time.now.to_i}.zip"
            tempfile = GeneratedTempfile.new(file_name)
            path = tempfile.path
            tempfile.unlink()
            Zip::ZipFile.open(path, Zip::ZipFile::CREATE) do |zf|
                for file in files
                    unless file_object_okay?(file)
                        tempfile.close()
                        zf.close()
                        raise "Non-files submitted in file field"
                    end
                    zf.get_output_stream(file.original_filename) do |o|
                      o.puts(file.read())
                    end
                    file.close()
                end
            end
            tempfile.reopen(path)
            self.file = tempfile
        elsif file_object_okay?(x)
            self.file = x
        else
            raise "Non-file submitted in file field"
        end
    end

    def institute=(x)
        self[:institute] = x.strip() unless x.blank?
    end

    def Country=(x)
        self[:Country] = x.strip() unless x.blank?
    end

    def clean_name
        return clean(self.name) || ''
    end

    def clean_filename
        default_name = 'default_clean_name'
        return clean(self.file.original_filename) || default_name if self.file
        return default_name
    end

    def unsave_file
        dir, filename, path = get_path_and_name()
        begin
            SUBMITLOG.info("Rolling back file save")
            if File.exist?(path)
                File.delete(path)
            end
            SUBMITLOG.info("Rolling back directory creation")
            if File.directory?(dir)
                FileUtils.rmdir(dir)
            end
        rescue
        end
    end

    def file_object_okay?(file)
        return false if file.blank?
        return true if file.kind_of?(StringIO)
        return true if file.kind_of?(Tempfile)
        return false
    end

    private 

    def save_file
        dir, filename, path = get_path_and_name()

        file = self.file
        unless file_object_okay?(file)
            SUBMITLOG.info("File to save is not of proper upload type. Maybe it was set directly?")
            raise
        end
        self.file = path

        begin
            File.open(path, 'wb') do |f|
                f.write(file.read())
            end
            file.close()
        rescue Exception => msg
            SUBMITLOG.info("Error while writing file: #{msg}")
            raise
        end

        SUBMITLOG.info("Submission file saved to: #{path}")
    end

    def clean(x)
        return x if x.blank?
        return x.gsub(/[^\w\.\-]/, '_')
    end

    def get_clean_directory_name
        # Generate clean directory name to store file (date_submitter_name)
        return "#{Time.now.strftime("%Y%m%d_%I_%M")}_#{clean_name()}"
    end

    def generate_unique_submission_directory
        new_dir_base = get_clean_directory_name()
        new_dir = new_dir_base
        begin
            while File.exists?($naming_lockfile)
            end
            # TODO There's still a locking gap!
            FileUtils.touch($naming_lockfile)
            while File.exists?(new_dir) and new_dir.length < 200
                new_dir += '_'
            end
            if File.exists?(new_dir)
                raise IOError("Filesystem has too many of the same " + 
                              "directories. Oversize directory: " + 
                              new_dir)
                return
            else
                save_dir = File.join($submission_root, new_dir)
                SUBMITLOG.info("Created submit dir: #{save_dir}")
                FileUtils.makedirs(save_dir)
            end
        ensure
            File.delete($naming_lockfile)
        end
        return save_dir
    end

    def get_path_and_name
        if self.file.kind_of?(String)
            # The file attribute is a string.
            # Use that to get the name and path.
            dir = File.dirname(self.file)
            filename = File.basename(self.file)
            path = self.file
        else
            dir = generate_unique_submission_directory()
            filename = clean_filename()
            path = File.join(dir, filename)
        end
        return dir, filename, path
    end

    def fill_in_default_values
        self.assigned = false
        self.assimilated = false
        self.submission_date = Time.now
    end
end

# Ensure the submission root is writeable
unless File.directory?($submission_root)
    raise "The submission root directory (#{$submission_root}) doesn't exist."
end
unless File.stat($submission_root).writable?
    raise "The submission root directory (#{$submission_root}) needs to be " + 
          "writeable by the server."
end
