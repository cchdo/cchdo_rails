RAILS_ENV = 'production'
require File.dirname(__FILE__) + '/../config/environment'
require "rubygems"
require "geo_ruby"
include GeoRuby::Shp4r

  
  
   # track_coords = Array.new
   # if track = Track.find(:first)
   #   coords = track.Track.split(/\n/)
   #   coords.each_index do |coord_i|
   #     if coord_i % 10 == 0
   #       track_coords << coords[coord_i]
   #     end
   #   end
   # end
    
    
  
  def get_track_line(expocode)
    if trackline = TrackLine.find(:first,:conditions => ["ExpoCode = '#{expocode}'"])
#      puts "#{trackline.inspect}  <-- INSPECTION!!"
      return trackline
    else
      return nil
    end
  end
  
    expocode = "3230CITHER2_1"
    
    #tline = create_track_line(expocode)
    tline = get_track_line(expocode)
    puts tline.Track.class
    points = tline.Track.points
#    points.each do |point|
#       puts point.inspect
#    end
    #for point in tline.Track
    #  puts "#{point.x}---#{point.y}"
    #end
#    puts "TLine: #{tline.class}  #{tline.inspect}"

shpfile = ShpFile.create('track_line.shp',ShpType::POLYLINE,[Dbf::Field.new('ExpoCode','C',20)])
tracklines = TrackLine.find(:all)

tracklines.each do |track_line|
if track_line.Track.points.length > 1
        shpfile.transaction do |tr|
                tr.add(ShpRecord.new(LineString.from_points(track_line.Track.points),'ExpoCode' => "#{track_line.ExpoCode}"))
                #tr.delete()
        end
end
end
shpfile.close

