class Event < ActiveRecord::Base
    belongs_to :cruise, :primary_key => :ExpoCode, :foreign_key => :ExpoCode

    def self.get_feed_events_for(expocode)
        events = self.find_all_by_ExpoCode(expocode,
                                           :order => "`Date_Entered` DESC")
        events
    end

    def feed_datetime
        dt = self.Date_Entered
        DateTime.civil(dt.year, dt.month, dt.day)
    end

    def feed_info
        {
            :title => "History | #{self.cruise.Line} #{self.ExpoCode} #{self.Data_Type} #{self.Action}: " + 
                      self.Summary,
            :content => [
                "<pre>", self.Note, "</pre>"].join(''),
            :author => "#{self.LastName}, #{self.First_Name}",
        }
    end
end
