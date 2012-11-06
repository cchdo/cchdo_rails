class Document < ActiveRecord::Base
    belongs_to :cruise, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'

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
      today = Date.today
      last_month = Date.new(today.year, today.mon - 1, today.day).to_s
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
