require 'set'

# Datacart contains files that are meant to be bulk downloaded.
class Datacart < Set
    extend Forwardable

    def initialize enum = nil, &block
        @hash = ActiveSupport::OrderedHash.new
        super
    end

    def cruise_files_in_cart(cruise)
        file_count = 0

        dir = cruise.directory
        mapped_files = cruise.get_files()
        for key, file in mapped_files
            next if key =~ /_pic$/
            if self.include?([dir.id, File.basename(file)])
                file_count += 1
            end
        end

        [file_count, mapped_files.length]
    end
end
