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
