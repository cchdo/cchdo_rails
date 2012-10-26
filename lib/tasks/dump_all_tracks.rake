require 'builder'
task :dump_all_tracks => :environment do
  # rake --silent dump_all_tracks RAILS_ENV=production > cchdo_all_tracks.txt

  class Cruise < ActiveRecord::Base
    has_one :track_line, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'
  end

  class TrackLine < ActiveRecord::Base
    belongs_to :cruise, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'
  end

  for cruise in Cruise.all()
    if not cruise.Begin_Date
      next
    end
    if not cruise.track_line
      next
    end
    for coord in cruise.track_line.Track
      puts "#{coord.lon},#{coord.lat},#{cruise.Begin_Date}"
    end
  end
end
