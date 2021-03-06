include Math 

include ActionView::Helpers::UrlHelper
include ActionView::Helpers::TagHelper
include DataAccessHelper
include DatacartHelper
include DocumentsHelper

class MapSearchController < SearchController
  layout 'standard'
  $RADIUS_EARTH = 6371.01 #km

  def index
    @ne_lat = params[:ne_lat] || '3.0'
    @ne_lng = params[:ne_lng] || '3.0'
    @sw_lat = params[:sw_lat] || '-3.0'
    @sw_lng = params[:sw_lng] || '-3.0'
  end

# These functions should find the Cruises to be displayed.

  def tracks
    min_time = params[:min_time].to_i
    max_time = params[:max_time].to_i

    if params[:tool] == 'expocodes' and params[:expocodes]
      params[:max_coords] = '100'
      @cruises = params[:expocodes].split(',').map {|expo| Cruise.first(:conditions => {:ExpoCode => expo})}
    elsif params[:tool] == 'query' and params[:query]
      #params[:query] += " year_start:#{min_time} month_start:0 year_end:#{max_time} month_end:12"
      find_by_params_query()
    elsif params[:tool] == 'rectangle'
      sw_lng, sw_lat = params[:sw_lng].to_f, params[:sw_lat].to_f
      ne_lng, ne_lat = params[:ne_lng].to_f, params[:ne_lat].to_f
      selection = [[sw_lng, sw_lat], [sw_lng, ne_lat], [ne_lng, ne_lat], [ne_lng, sw_lat]]
      raw_tracks = getTracksInSelection(selection, min_time, max_time)
      # Re-filter because MySQL only selects for MBRIntersect :(
      tracks = raw_tracks.select {|track| track_in_selection?(track_to_a(track.Track), selection)}
      @cruises = tracks.map {|track| Cruise.first(:conditions => {:ExpoCode => track.ExpoCode})}
    elsif params[:tool] == 'circle'
      center = [params[:circle_center_lng], params[:circle_center_lat]].map {|x| deg_to_rad(x.to_f)}
      radius = params[:circle_radius].to_f #km
      radian_radius = radius / 1.86 * 0.0002908882087 # 1.86km -> 1' -> 0.002rad

      # diamond around center; intersect only does min bounding rectangle :(
      pseudo_polygon = [[center.first-radian_radius, center.last],
                        [center.first, center.last+radian_radius],
                        [center.first+radian_radius, center.last],
                        [center.first, center.last-radian_radius]]
      # sanitize polygon
      pseudo_polygon.map! {|coord| coord.map {|x| x += PI while x < -PI/2; x -= PI while x > PI/2; rad_to_deg(x) }}
      
      raw_tracks = getTracksInSelection(pseudo_polygon, min_time, max_time)
      tracks = raw_tracks.select {|track| track_in_circle?(center, radius, track_to_a(track.Track))}
      @cruises = tracks.map {|track| Cruise.first(:conditions => {:ExpoCode => track.ExpoCode})}
    elsif params[:tool] == 'polygon'
      # TODO fix for dateline
      polygon = linestring_to_a(params[:polygon]) # Incoming as line string
      raw_tracks = getTracksInSelection(polygon, min_time, max_time)
      tracks = raw_tracks.select {|track| track_in_polygon?(polygon, track_to_a(track.Track))}
      @cruises = tracks.map {|track| Cruise.first(:conditions => {:ExpoCode => track.ExpoCode})}
    elsif params[:tool] == 'import'
      @centers = linestring_to_a("LINESTRING(#{params[:latlons].gsub(',', ' ').gsub("\n", ',')})")
      @radius = params[:import_radius].to_f
      @cruises = Array.new
      loci = flip_lnglat(@centers).map {|latlon| latlon.map {|x| deg_to_rad(x)}}
    
      arclen = @radius / $RADIUS_EARTH
      boxes = Array.new
      loci.each do |center|
        deltacoord = acos((cos(arclen) - sin(center.first) ** 2) / cos(center.first) ** 2)
        boxes.push([[center.first-deltacoord, center.last-deltacoord], [center.first+deltacoord, center.last+deltacoord]])
      end
      sws = boxes.collect {|box| box.first}
      nes = boxes.collect {|box| box.last}
      sw = [sws.collect {|coord| coord.first}.min, sws.collect {|coord| coord.last}.min]
      ne = [nes.collect {|coord| coord.last}.max, nes.collect {|coord| coord.last}.max]
      box = [sw.map {|x| rad_to_deg(x)}, ne.map {|x| rad_to_deg(x)}]
    
      getTracksInSelection(box).map {|trackline| trackline.Track = track_to_a(trackline.Track); trackline}.each do |track|
        loci.each do |center|
          if track_in_circle?(center, @radius, track.Track)
            @cruises << Cruise.first(:conditions => {:ExpoCode => track.ExpoCode})
          end
        end
      end
      @cruises.uniq!
    elsif params[:tool] == 'none'
      logger.warn "No tool selected. HTTP params: #{params.inspect}"
    else
      logger.warn "No tool selected at all."
    end

    reduce_specifics(@cruise)

    cruise_tracks = {}
    unless @cruises.blank?
      max_coords = params[:max_coords].to_i
      @cruises.each do |cruise|
        # Get track from the cruise or fall back to the tracklines table
        if cruise.has_attribute? :Track
          track = cruise.Track
        else
          track = TrackLine.first(:select => 'Track', :conditions => {:ExpoCode => cruise.ExpoCode})
        end
        if track and track.Track
          cruise_tracks[cruise.ExpoCode] = flip_lnglat(pareDown(track_to_a(track.Track), max_coords))
        else
          cruise_tracks[cruise.ExpoCode] = []
        end
      end
    end
    tracks = {
        :cruises => cruise_tracks,
        :datacart_all_link => datacart_link_cruises(@cruises, {:class => "data-formats"})
    }
    render :json => tracks
  end

  def info
    @info = {}
    if cruise = Cruise.first(:conditions => {:ExpoCode => params[:expocode]})
      reduce_specifics(cruise)
      @info = {
        :line => (cruise.Line || '').strip,
        :ship => (cruise.Ship_Name || '').strip,
        :country => (cruise.Country || '').strip,
        :pi => DataAccessHelper.contact_cruises(cruise),
        :date_begin => (cruise.Begin_Date || ''),
        :cruise_id => cruise.id,
        :data => show_files(cruise, load_files_and_params(cruise)[0], short=true),
        #:date_end => cruise.EndDate,
        #:aliases => cruise.Alias,
        #:groups => cruise.Group
      }
    end
    render :json => @info
  end

  def mirror
    map_search_mirror = File.join(RAILS_ROOT, 'public', 'map_search_mirror')
    unless File.directory? map_search_mirror then Dir.mkdir(map_search_mirror) end
    Dir.foreach(map_search_mirror) do |file|
      next if file =~ /\./
      if file.to_i < Time.now.to_i - 60 
        File.unlink(File.join(map_search_mirror, file))
      end
    end
    filename = File.join(map_search_mirror, Time.now.to_i.to_s)
    f = File.new(filename, 'w')
    params[:kml].each_line {|line| f.write line }
    f.flush
    f.close
    render :text => "map_search_mirror/#{File.basename filename}"
  end
  
private

  def getTracksInSelection(selection, min_time=nil, max_time=nil)
    selection << selection.first # add start point at end for polygon
    polygon_string = selection.map{|x| x.join(' ')}.join(',')

    min_time, max_time = min_time || 1975, max_time || Date.today.year
    return TrackLine.find_by_sql(["SELECT DISTINCT cruises.ExpoCode,Track FROM track_lines JOIN cruises ON cruises.ExpoCode = track_lines.ExpoCode WHERE Begin_Date > '?' AND Begin_Date < '?-12-31' AND Intersects(GeomFromText(\"POLYGON((#{polygon_string}))\"),Track)", min_time, max_time])
  end

  def pareDown(coords, max=20)
     pared = []
     if max <= 0 then max = 1 end
     step_size = coords.length / max
     if step_size == 0 then step_size = 1 end
     (0...coords.length).step(step_size) {|index| pared << coords[index]}
     return pared
  end

  def between_lat (lower, test, upper)
    return (lower..upper).include? test
  end

  def between_lng (lower, test, upper)
    if lower > upper # crossed the date-line
      return (lower <= test && test <= 180) || (-180 <= test && test <= upper)
    end
    return lower <= test && test <= upper
  end

  def in_polygon?(polygon, point)
    len = polygon.length
    i = 0
    j = len - 1
    c = false
    while i < len
      ver1 = polygon[i]
      ver2 = polygon[j]
      if ((ver1.last > point.last) != (ver2.last > point.last)) and (point.first < (ver2.first - ver1.first) * (point.last-ver1.last) / (ver2.last-ver1.last) + ver1.first)
        c = !c
      end
      j = i
      i += 1
    end
    return c
  end

  def linestring_to_a(linestring)
    unless linestring
      return []
    end
    linestring.delete("LINESTRING()").split(",").collect {|coord_s| coord_s.split.map {|x| x.to_f}}
  end

  def track_to_a(track)
    track.points.collect {|point| [point.x, point.y]}
  end

  def track_in_selection?(track, selection)
    min, max=selection[0], selection[2]
    track.each {|coordinate| return true if between_lng(min[0], coordinate[0], max[0]) and between_lat(min[1], coordinate[1], max[1])}
    return false
  end

  def track_in_circle?(center, radius, track)
    track.map{|x| x.map{|y| deg_to_rad(y)}}.each do |latlon|
      dist = gc_distance(center.first, center.last, latlon.first, latlon.last)
      return true if dist <= radius and dist > 0
    end
    return false
  end

  def track_in_polygon?(polygon, track)
    track.each {|coordinate| return true if in_polygon?(polygon, coordinate)}
    return false
  end

  def flip_lnglat(track)
    new_track = Array.new
    track.each do |coord| 
      new_track << [coord[1], coord[0]]
    end
    return new_track
  end

  def gc_distance(lon_stand, lat_stand, lon_fore, lat_fore)
    delta_lon = lon_fore - lon_stand
    delta_lat = lat_fore - lat_stand
    begin
      # haversine formula
      central_angle = 2*asin(sqrt(sin(delta_lat/2)**2+cos(lat_stand)*cos(lat_fore)*sin(delta_lon/2)**2))
      # Vincenty's
      #central_angle = atan( sqrt( (cos(lat_fore) * sin(delta_lon))**2 + (cos(lat_stand) * sin(lat_fore) - sin(lat_stand) * cos(lat_fore) * cos(delta_lon))**2) / (sin(lat_stand) * sin(lat_fore) + cos(lat_stand) * cos(lat_fore) * cos(delta_lon)))
    rescue
      central_angle = 0
    end
  
    $RADIUS_EARTH * central_angle
  end
  
  def deg_to_rad(deg)
    deg * PI / 180.0
  end

  def rad_to_deg(rad)
    rad * 180.0 / PI
  end

    # unused
    def track_coords_in(expocode)
        # Returns an array of track coordinates for given expocode.
        track_coords = Array.new
        if track = Track.find(:first, :conditions => { :ExpoCode => expocode})
            coords = track.Track.split(/\n/)
            coords.each_index do |coord_i|
                if coord_i % 10 == 0
                    track_coords << coords[coord_i]
                end
            end
        end
        return track_coords
    end

    # unused
    def switch_x_y_polygon(polygon)
        rings = polygon.rings
        @points = []
        for ring in rings 
            for coord in ring
                @points << Point.from_x_y(coord.y,coord.x)
            end
        end
        poly = Polygon.from_points([@points])
        return poly
    end
end
