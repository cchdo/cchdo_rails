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
      if pi
        # Take Chief Scientist string and extract multiple names
        pi_names = pi.split(/\/|\\|\:/)
        # Substitute name matches for links to the contact's page
        pi_names.each do |name|
          if Contact.exists?(:LastName => name)
            pi.sub!(name, "<a href=\"/search?query=#{name}\">#{name}</a>")
          end
        end
      end
      pi
    end

    def chisci_to_links
        # Regular expression for exctracting multiple names from Chief_Scientist
        if not self.Chief_Scientist
            return
        end
        pi_names = self.Chief_Scientist.scan( /([a-z]+)\/?\\?([a-z]*):?\/?([a-z]*)\/?\\?([a-z]*)/i)
        #Substitute name matches for links to the contact's page
        #if @pi_names.length > 1
        for group in pi_names
            for name in group
                # This says Dickson, MAFF, , . I don't know what's up with the extra empty string entries.
                RAILS_DEFAULT_LOGGER.warn("#{name} is in #{group} in #{pi_names}")

                if pi_found = Contact.find_by_LastName(name)
                    chisci = self.Chief_Scientist.sub(/(#{name})/,"<a href=\'/contact?contact=#{name}\'>#{name}</a>")
                end
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
