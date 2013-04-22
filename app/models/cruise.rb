require 'track_line'

class Cruise < ActiveRecord::Base
    #set_primary_key :Entry
    has_and_belongs_to_many :collections
    has_many :documents, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'
    has_one :track_line, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'

    has_many :contact_cruises
    has_many :contacts, :through => :contact_cruises

    validates_presence_of :ExpoCode

    validates_format_of :ExpoCode,
                        :with => /^\w+$/,
                        :message => "is missing or invalid"

    validates_format_of :Chief_Scientist,
                        :with => /^[\w\s\.:\/\'\(\)-\\]+$/,
                        :message => "is missing or invalid",
                        :allow_nil => true

    validates_format_of :Ship_Name,
                        :with => /^[\w\'\/\.\s\(\)-]+$/,
                        :message => "is missing or invalid",
                        :allow_nil => true

    validates_format_of :Line,
                        :with => /^[\w\/-]+$/,
                        :message => "is missing or invalid",
                        :allow_nil => true

    validates_format_of :Country,
                        :with => /^[\w-]+$/,
                        :message => "is missing or invalid",
                        :allow_nil => true

    def directory
        return Document.find_by_ExpoCode_and_FileType(self.ExpoCode, 'Directory')
    end

    def data_dir
        return self.directory.FileName
    end

    def get_files
        if directory = self.directory
            directory.get_files()
        else
            {}
        end
    end
end
