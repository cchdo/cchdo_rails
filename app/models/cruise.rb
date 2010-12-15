class Cruise < ActiveRecord::Base
    #set_primary_key :Entry
    has_and_belongs_to_many :contacts
    has_and_belongs_to_many :collections
    has_many :documents, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'

    validates_presence_of :ExpoCode
    #validates_uniqueness_of :ExpoCode,
    #                        :message => "is not unique"

    validates_format_of :ExpoCode,
                        :with => /^\w+$/,
                        :message => "is missing or invalid"

    validates_format_of :Chief_Scientist,
                        :with => /^[\w\.:\/\\\s\'\(\)]+$/,
                        :message => "is missing or invalid"

    validates_format_of :Ship_Name,
                        :with => /^[\w\'\.\s\(\)]+$/,
                        :message => "is missing or invalid"

    validates_format_of :Line,
                        :with => /^\w+$/,
                        :message => "is missing or invalid"

    validates_format_of :Country,
                        :with => /^\w+$/,
                        :message => "is missing or invalid"
end
