#!/usr/bin/env ruby

RAILS_ENV = 'production'
require File.dirname(__FILE__) + '/../config/environment'
  
unless ARGV[0] 
  puts "Please enter a file with coordinates in csv: Lon,Lat/\n."
  coord_file = gets().strip()
else
  coord_file = ARGV[0] or raise "Please include a file with coordinates"
end
file_obj = File.open(coord_file) or raise "Couldn't open #{file}"
coordinates = file_obj.read

puts "Please enter an ExpoCode:"
expocode = STDIN.gets().chomp
@coordinates = String.new
@point_array = []
# Create a TrackLine object and save it in track_lines
for coordinate in coordinates#_with_station_cast_code
  (lon,lat) = coordinate.strip.split(/\s+|,/)
  if lat and lon
    @point_array << Point.from_x_y(lon.to_f,lat.to_f )
  end
end
trackline = TrackLine.first(:conditions => {:ExpoCode => expocode}) ||
            TrackLine.new(:ExpoCode => expocode, :Basins => "Default")
if trackline
puts "Got a trackline = #{@point_array.inspect}"
  begin
    trackline.Track = LineString.from_points(@point_array)
    trackline.save
    puts "saved #{coord_file}"
  rescue
    puts "Couldn't save #{coord_file}'s coordinates into db. \n#{$!}"
  end
end
