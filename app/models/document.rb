class Document < ActiveRecord::Base
    belongs_to :cruise, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'

    # Return a hash of short file name to file path
    def get_files
        @file_result = Hash.new
        unless self.FileType == "Directory"
            return @file_result
        end

        @files = self.Files.split(/\s/)
        trash, path = self.FileName.split(/data/)
        unless @files
            return @file_result
        end

        for file in @files
           unless file
               continue
           end
           if file =~ /\*$/
              file.chop!
           end
           key = case file
               when /su.txt$/ then 'woce_sum'
               when /ct.zip$/  then 'woce_ctd'
               when /hy.txt$/  then 'woce_bot'
               when /lv_hy1.csv$/ then 'exchange_large_volume'
               when /lv.txt$/ then 'large_volume'
               when /lvs.txt$/ then 'large_volume'
               when /tm_hy1.csv$/ then 'trace_metal'
               when /hy1.csv$/ then 'exchange_bot'
               when /ct1.zip$/ then 'exchange_ctd'
               when /ctd.zip$/ then 'netcdf_ctd'
               when /hyd.zip$/ then 'netcdf_bot'
               when /do.txt$/  then 'text_doc'
               when /do.pdf$/  then 'pdf_doc'
               when /.gif$/    then 'big_pic'
               when /.jpg$/    then 'small_pic'
               else nil
           end
           if key
               @file_result[key] = "/data#{path}/#{file}"
           end
           @lfile = file
        end

        return @file_result
    end

    $feed_file_whitelist = [
        "Exchange Bottle", "Exchange Bottle (Zipped)",
        "Exchange CTD", "Exchange CTD (Zipped)", 
        "Documentation", "PDF Documentation",
        "NetCDF CTD", "NetCDF Bottle",
        "Woce Sum", "Woce CTD (Zipped)", "Woce Bottle", "CTD File", 
        "WCT CTD File", "SEA file", "Sum File", "Encrypted file",
        "JGOFS File", "Large Volume file", "Matlab file",
    ]

    def self.get_feed_documents_for(expocode)
        documents = self.find_all_by_ExpoCode(expocode,
                                              :order => "`LastModified` DESC")
        documents.reject! {|d| ! $feed_file_whitelist.include?(d.FileType) }
        documents
    end

    def self.recently_edited_expocodes(num=5)
      excluded_filetypes = ['directory', 'Small Plot', 'Large Plot']
      sql_excluded_filetypes = excluded_filetypes.map {|f| "FileType != ?"}
      last_month = Date.today << 1
      Document.all(
        :select => "DISTINCT ExpoCode",
        :conditions => [
          (['ExpoCode IS NOT NULL',
            "ExpoCode != 'NULL'",
            "ExpoCode != ''",
            "ExpoCode != 'no_expocode'",
            "LastModified > ?",
           ] + sql_excluded_filetypes
          ).join(' AND ')] + [last_month] + excluded_filetypes,
        :order => 'LastModified DESC',
        :limit => 100
      ).map {|x| x.ExpoCode}
    end

    def feed_datetime
        self.LastModified
    end

    def feed_info
        {
            :title => "Document | (#{self.cruise.Line}) #{self.ExpoCode}: " + 
                      self.FileType,
            :content => [
                "<a href=\"#{self.FileName}\">", self.FileName,
                "</a>"].join(''),
            :author => 'CCHDO',
        }
    end
end
