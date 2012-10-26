require 'zip/zip'

module StaffHelper
    def multiple_files_names(multifile_path)
        names = []
        begin
            Zip::ZipFile.open(multifile_path) do |zf|
                zf.each do |entry|
                    names << entry.name
                end
            end
        rescue
        end
        return names
    end
end
