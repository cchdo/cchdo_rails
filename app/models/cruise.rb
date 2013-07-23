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

    # Return the Chief_Scientist field with the chief scientists into links if
    # we have a contact entries that match.
    def chief_scientists_as_links
        pi = self.Chief_Scientist
        return pi if not pi

        # Take Chief Scientist string and extract multiple names
        pi_names = pi.split(/\/|\\|\:/)

        # Substitute name matches for links to the contact's page
        for name in pi_names
          if Contact.exists?(:LastName => name)
            pi.sub!(name, "<a href=\"/search?query=#{name}\">#{name}</a>")
          end
        end
        pi
    end

    def chisci_to_links
        chisci = self.Chief_Scientist
        return if not chisci

        # Regular expression for extracting multiple names from Chief_Scientist
        name_chars = '[a-zA-Z-]'
        pi_names = self.Chief_Scientist.scan(/(#{name_chars}+)\/?\\?(?:#{name_chars}*):?\/?(?:#{name_chars}*)\/?\\?(?:#{name_chars}*)/).flatten
        Rails.logger.warn("app.models.cruise.chisci_to_links: #{chisci.inspect} -> #{pi_names.inspect}")

        # Substitute name matches for links to the contact's page
        for name in pi_names
            Rails.logger.warn("app.models.cruise.chisci_to_links: trying last name #{name}")

            if Contact.exists?(:LastName => name)
                chisci = self.Chief_Scientist.sub(name, "<a href=\'/contact?contact=#{name}\'>#{name}</a>")
            end
        end
        chisci
    end

    def directory
        return Document.find_by_ExpoCode_and_FileType(self.ExpoCode, 'Directory')
    end

    def data_dir
        if directory = self.directory
            directory.FileName
        else
            nil
        end
    end

    def get_files
        if directory = self.directory
            directory.get_files()
        else
            {}
        end
    end
end
