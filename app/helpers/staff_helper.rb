require 'zip/zip'

module StaffHelper
    def multiple_files_names(multifile_path)
        names = []
        Zip::ZipFile.open(multifile_path) do |zf|
            zf.each do |entry|
                names << entry.name
            end
        end
        return names
    end

    def limit_str_len(s, limit, trailer='...')
        if s.length > limit
            return s.slice(0..limit - trailer.length) + trailer
        end
        return s
    end
end
