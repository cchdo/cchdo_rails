class MapSelectController < ActionController::Base
	def index
		if params[:min_lat]
			map_select
			render :action => 'map_select'
		elsif params[:expocodes]
			cruise_html
			render :action => 'cruise_html'
		else
			map_select
			render :action => 'map_select'
		end
	end

	def map_select
		@expocodes = Hash.new
		
		max_coords = params[:max_coords].to_i
		selection=[[params[:sw_lat].to_f, params[:sw_lng].to_f], [params[:ne_lat].to_f, params[:ne_lng].to_f]]

		if params[:min_time] or params[:max_time]
			min_time = params[:min_time].to_i
			max_time = params[:max_time].to_i
			tracks = Track.find_by_sql(["SELECT Tracks.ExpoCode,Tracks.Track from Tracks INNER JOIN Cruises ON Cruises.ExpoCode = Tracks.ExpoCode WHERE Cruises.Begin_Date > '?' AND Cruises.Begin_Date < '?'",min_time,max_time])
		else
			tracks = Track.find(:all,
			                    :select     => "ExpoCode,Track")
		end
		for track in tracks
			track_coors = parse_track_to_array(track.Track)
			if track_in_selection(track_coors, selection)
#Experiment failed?
#				max_coords = max_coords / tracks.size();
#End Experiment
				pareDown(track_coors, max_coords)
				@expocodes[track.ExpoCode] = track_coors
			end
		end
	end

	def pareDown(coords, max)
		i = 1
		while coords.length > max
			coords.delete_at(i)
			i = (i+1).modulo(coords.length) + 1
		end
	end

	def shift_coor(coor)
#		return [(coor[0] + 180) % 180, (coor[1] + 360) % 360]
		return [(coor[0] + 270) % 180, (coor[1] + 540) % 360]
	end

	def between_lat (lower, test, upper)
		if lower > upper
			if lower <= test and test <= 90 || -90 <= test <= upper
				return true
			end
		elsif lower <= test and test <= upper
			return true
		else
			return false
		end
	end

	def between_lng (lower, test, upper)
		if lower > upper
			if lower <= test and test <= 180 || -180 <= test <= upper
				return true
			end
		elsif lower <= test and test <= upper
			return true
		else
			return false
		end
	end
	
	def parse_coord_s_to_array(coord_s)
		coords=coord_s.split
		return [coords[0].to_f, coords[1].to_f]
	end
	
	def parse_track_to_array(track)
	        latlon=track.split("\n")
	        array=[]
	        for coord_s in latlon
	                array.push(parse_coord_s_to_array(coord_s))
	        end
	        return array
	end

	def track_in_selection(track, selection)
#		min, max=shift_coor(selection[0]), shift_coor(selection[1])
	        min, max=selection[0], selection[1]
	        for coordinate in track
#			coordinate=shift_coor(coordinate)
			if between_lat(min[0], coordinate[0], max[0]) and between_lng(min[1], coordinate[1], max[1])
	                        return true
	                end
	        end
	        return false
	end

	def cruise_html
		@cruises = []
		expocodes = params[:expocodes].split(",")
		for expocode in expocodes
			@cruises << Cruise.find(:first,
						:conditions	=> ["`ExpoCode` = '#{expocode}'"])
		end
        reduce_specifics(@cruises)
	end
end
