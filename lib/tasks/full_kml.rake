require 'builder'
task :full_kml => :environment do
  # rake --silent full_kml RAILS_ENV=production > output.kml

  class Cruise < ActiveRecord::Base
    has_one :track_line, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'
  end

  class TrackLine < ActiveRecord::Base
    belongs_to :cruise, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'
  end

  class SpatialGroup < ActiveRecord::Base
    has_one :cruise, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'
  end

  #basin = 'southern'
  #basin = 'indian'
  #basin = 'atlantic'
  basin = 'pacific'

  if basin == 'southern'
    title = 'CCHDO Southern'
    cruises = SpatialGroup.all(:conditions => {:southern => true})
    tracks = cruises.map do |x|
      if line = x.cruise.track_line
        line
      else
        nil
      end
    end
  elsif basin == 'indian'
    title = 'CCHDO Indian'
    cruises = Cruise.all(:conditions => ["`Group` LIKE ?", "%indian%"])
    tracks = cruises.map do |x|
      if line = x.track_line
        line
      else
        nil
      end
    end
  elsif basin == 'atlantic'
    title = 'CCHDO Atlantic'
    cruises = Cruise.all(:conditions => ["`Group` LIKE ?", "%atlantic%"])
    tracks = cruises.map do |x|
      if line = x.track_line
        line
      else
        nil
      end
    end
  elsif basin == 'pacific'
    title = 'CCHDO Pacific'
    cruises = Cruise.all(:conditions => ["`Group` LIKE ?", "%pacific%"])
    tracks = cruises.map do |x|
      if line = x.track_line
        line
      else
        nil
      end
    end
  end

  #all_tracks =  TrackLine.all(:select => "DISTINCT ExpoCode, Track")
  all_tracks = tracks.compact

  every = 10

  xml = Builder::XmlMarkup.new(:target => STDOUT, :indent => 1)
  xml.instruct!
  xml.kml(:xmlns => "http://www.opengis.net/kml/2.2") do
    xml.Document do 
      xml.name(title)
      xml.Style(:id => :cchdofirst) do
        xml.IconStyle do
          xml.Icon do
            xml.href('http://cchdo.ucsd.edu/images/ship.png')
          end
        end
        xml.LineStyle do
          xml.color('aa00ffff')
        end
      end
      xml.Style(:id => :cchdo) do
        xml.IconStyle do
          xml.color('aa00ffff')
          xml.scale(0.5)
          xml.Icon do
            xml.href('http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png')
          end
        end
        xml.LineStyle do
          xml.color('aa00ffff')
        end
      end
      for track in all_tracks
        track_pts = track.Track
        xml.Placemark do
          xml.styleUrl('#cchdofirst')
          line = track.cruise.Line
          line = "(#{line})"if line
          xml.name([track.ExpoCode, line].join(' '))
          pt = track_pts.shift
          xml << pt.as_kml
        end
        xml.Placemark do
          xml.styleUrl('#cchdo')
          #xml << track.Track.as_kml
          xml.MultiGeometry do
            for pt in track_pts
              xml << pt.as_kml
            end
          end
        end
      end
    end
  end
end
