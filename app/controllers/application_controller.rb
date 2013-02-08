# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class BottleDB < ActiveRecord::Base
end

def getGAPIkey(host)
  return case host
    #when 'cchdo.ucsd.edu' then 'ABQIAAAAZICfw-7ifUWoyrSbSFaNixTec8MiBufSHvQnWG6NDHYU8J6t-xTRqsJkl7OBlM2_ox3MeNhe_0-jXA'
    when 'cchdo.ucsd.edu' then 'ABQIAAAATXJifusyeTqIXK5-oRfMqRTec8MiBufSHvQnWG6NDHYU8J6t-xQu6FK5KGtXjapXKCGo-If8o-ibsQ'
    #when 'whpo.ucsd.edu' then 'ABQIAAAATXJifusyeTqIXK5-oRfMqRRrtQtAbE2ICKyeJmE150l9FUtvWRQ_qb0gC6W0P4gBV_W3RstdZXEcOw'
    #when 'watershed.ucsd.edu' then 'ABQIAAAATXJifusyeTqIXK5-oRfMqRRkZzjLi0nUJ4TwOC8xt4Ov2IJhKBQTGSNz9nt4_eT3w1Wv_O1VSaMyBA'
    #when 'ushydro.ucsd.edu' then 'ABQIAAAATXJifusyeTqIXK5-oRfMqRRtY8Vb6BVQ_NYWg4_c_l3k0L4OIhQFByUZ1IXeNowVep-DwxF7cwWzVg'
    #when 'ushydro.ucsd.edu:3000' then 'ABQIAAAATXJifusyeTqIXK5-oRfMqRQE8zGWDTi-uP6FZiwQgVhVR-BtSxRIgqf0aU_WJtUPpTZNUXmvRubneQ'
    #when 'ghdc.ucsd.edu' then 'ABQIAAAAZICfw-7ifUWoyrSbSFaNixRCPOjKkl_WpOSxLSW5BpFmpsf_3BSArp5f0mTCYw9o7efmB5J3NGXrXg'
  end
end

class Array
  def oob_to_nil
    oob_value = -999
    oob_tolerance = 1
    return self.map do |x|
      if oob_value-oob_tolerance <= x and x <= oob_value+oob_tolerance
        nil
      else
        x
      end
    end
  end
end

class ApplicationController < ActionController::Base
    layout 'standard'

    # Scrub sensitive parameters from your log
    filter_parameter_logging :password, :password_confirmation

    protect_from_forgery

    def signin
        if request.post?
            if user = User.authenticate(params[:username], params[:password])
                session[:user] = user.id
                session[:username] = params[:username]
                intended_path = session[:intended_path] or '/'
                redirect_to intended_path
            else
                flash[:notice] = "Invalid user name or password"
            end
        end
    end

    def signout
        session[:user] = nil
        redirect_to signin_path
    end

    def needs_reduction(cruise, date)
        return false unless cruise

        return false if session[:user]

        if (    (cruise.ExpoCode and cruise.ExpoCode =~ /^3[1-3]/) and 
                ((cruise.Begin_Date and cruise.Begin_Date > date) or
                 (cruise.EndDate and cruise.EndDate > date)))
            return true
        end
        return false
    end

    def reduce_specifics(cruises)
        # Comply with federal security regulations and remove specifics about
        # USA ships in the future
        # specifics include ports of call and departure/arrival dates
        # It is allowed to specify year, however.
        if cruises.nil?
            return cruises
        end
        today = Date.today
        was_singular = false
        if cruises.kind_of?(Cruise) or cruises.kind_of?(CarinaCruise)
             was_singular = true
             cruises = [cruises]
        end
        cruises.each do |cruise|
            if needs_reduction(cruise, today)
                Rails.logger.info(
                    "Reducing specifics for cruise #{cruise.ExpoCode}")
                if cruise.Begin_Date
                    cruise.Begin_Date = Date.new(cruise.Begin_Date.year)
                end
                if cruise.EndDate
                    cruise.EndDate = Date.new(cruise.EndDate.year)
                end
            end
        end
        if was_singular
            return cruises[0]
        end
        return cruises
    end

    protected

    def check_authentication
        unless session[:user]
            session[:intended_path] = request.path
            redirect_to signin_path
        else
            user = User.find(session[:user])
            if user.username =~ /guest/
                redirect_to :controller => :staff
            end
        end
    end

    def chief_scientists_to_links!(pi)
    # Turn the chief scientists into links if we have a contact entries.
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
    end

  def thumbnail_uri(expocode)
      if map = Document.find(:first, :conditions => { :ExpoCode => expocode, :FileType => 'Small Plot'})
        return map.FileName[0..-5]
      end
      return nil
    end

  def best_query_type(query)
    best_queries = Hash.new
    param_queries = Array.new

    ignored_queries = ['commit', 'action', 'controller', 'post', 'FileType', 'limit', 'skip']
    queries = parse_query_string(query) - ignored_queries

    keywords = {'group' => '`Group`', 'chief_scientist' => 'Chief_Scientist', 
                'expocode' => 'ExpoCode', 'alias' => 'Alias', 
                'ship_name' => 'Ship_Name', 'ship' => 'Ship_Name',
                'year_start' => 'year_start', 'year_end' => 'year_end',
                'month_start' => 'month_start', 'month_end' => 'month_end',
                'date' => 'Date', 'line' => 'Line'}
    parameters = Parameter.column_names

    # See if we recognize the query type
    queries.each do |query|
      # Query term is in format 'keyword:value'
      if query =~ /(\w+\:\w+)/
        keyword, value = query.split(':', 2)
        if keywords.include?(keyword.downcase.strip)
          best_queries[keywords[keyword.downcase]] = value
        end
      elsif query =~ /^([a-zA-Z]{1,3})(\d{1,2})$/i # Line number
        query = "#{$1}#{$2}"
        # Change queries formatted like I9, or A6 to be I09 or A06
        if $2.length == 1
           query = "#{$1}0#{$2}"
        end
        best_queries['Line'] = query
      elsif query =~ /\b\d{4}\b/
        best_queries['Date'] = query
      elsif country = COUNTRIES[query.downcase]
        best_queries['Country'] = country
      elsif parameters.include? query.upcase
        param_queries << query
      elsif query.downcase =~ /\ball\b/i
        best_queries['All'] = ' All results are on this page.'
      else # Resort to highest number of matches
        best_queries[find_best_query(query)] = query
      end
    end

    best_queries.delete_if {|key, value| key.empty?}
    return best_queries, param_queries
  end
  
  COLUMNS = {
    'Group' => 'Group',
    'Chief_scientist' => 'Chief_Scientist',
    'Expocode' => 'ExpoCode',
    'Alias' => 'Alias',
    'Ship_name' => 'Ship_Name',
    'Ship' => 'Ship_Name',
    'Line' => 'Line',
    'Parameter' => 'Parameter'
  }
  @testing = ""
  def find_by_params_query
    if (params[:query])
       @query_link = "search?query=#{params[:query]}"
       @query_with_sort_link = "#{@query_link}"
       @q_pass = params[:query]
       @query = params[:query].upcase
       @query.strip!
       if @query =~ /\w/
          @sort_statement = ""
          @sort_check = ["Line","ExpoCode","Begin_Date","Ship_Name","Chief_Scientist","Country"]
          if params[:Sort]
            @sort_by = params[:Sort]
            if @sort_check.include?(@sort_by)
              @sort_statement = "ORDER BY cruises.#{@sort_by}"
              @query_with_sort_link << "&Sort=#{@sort_by}"
            end
          end
          # Initializations ##
          @queries = []
          @queries = @query.split(/\s+/) # Make an array that contains all queries, as split by whitespace
          @best_result = Hash.new
          @cruises = Hash.new
          @parameter_columns = Parameter.columns.map {|col| col.name}
          @param_queries = []
          @param_list = Hash.new{|h,k| h[k]={}}
          # Initializations ##
          for query in @queries
             @cols = []
             @names = []
             @results = []
             @cur_max = 0
             @dir = []
             @text
             @line_query = nil
             @date_query = nil
             # Special Case 1: Token Search
             #  associate the query with it's requested
             #  column in the best_result hash
             if (query =~ /^(\w*)\:(\w*)$/)
                @tok= $1.capitalize
                @val = $2.downcase.capitalize
                if COLUMNS.keys.include? @tok
                  if @tok == 'Parameter'
                    @param_queries << query
                  else 
                    @best_result[$2] = COLUMNS[@tok]
                  end
                end
             end

             # Change queries formated like I9, or A6
             # to be I09 or A06
             #if (query =~ /^[a-zst][0-9]$/i)
             #   letters = query.split(//)
             #   query = "#{letters[0]}0#{letters[1]}"
             #end
             if (query =~/^[a-zA-Z]{1,3}\d{1,2}$/i)
                if query =~/^([a-zA-Z]{1,3})(\d)$/
                   query = "#{$1}0#{$2}"
                end
                @line_query = query
             end
             # If the search contains a full country name, replace it with
             # the cchdo country abreviation
             if COUNTRIES[query.downcase]
                query = COUNTRIES[query.downcase]
             end
             # Check for four digit year queries
             if query =~ /^\d{4}$/
                @date_query = query
             end
             if @parameter_columns.include?(query)
                @param_queries << query
             end
             #Search against every column within the cruise database
             #Keep the result with the most matches UNLESS the query format is recognized
             if @line_query and Cruise.count(:conditions => ["Line REGEXP ?", @line_query]) > 0
               @best_result[query] = "Line"
             else
                for column in Cruise.columns
                   if (column.name !~ /14C/)
                      @names << column.human_name
                      @results = reduce_specifics(Cruise.find(:all ,:conditions => ["`#{column.name}` regexp '#{query}'"]))
                      if @date_query and @results.length > 0 and column.name.eql?("Begin_Date")
                         @best_result[query] =  "Date"
                         break  # Break out of the for column in Cruise.columns loop
                      end
                      if @results.length > @cur_max
                         @cur_max = @results.length
                         @best_result[query] = column.name#@results
                         @results=[]
                      end
                   end
                end
             end
          end # for query in @queries

          #Build sql query based on best results
          where_clauses = []
          if @best_result.keys.length > 0
             for query in @best_result.keys
                if @best_result[query] =~ /Date/
                   where_clauses << "(Begin_Date regexp '#{query}' or EndDate regexp '#{query}')"
                else
                   where_clauses << "cruises.#{@best_result[query]} regexp '#{query}'"
                end
                if @param_queries.length > 0
                   for q in @param_queries
                      where_clauses << "parameters.`#{q}` != 'NULL'"
                   end
                end
             end
             where_clause = where_clauses.join(' AND ')
             select_clause = 'cruises.ExpoCode,cruises.Line,cruises.Ship_Name,cruises.Country,cruises.Begin_Date,cruises.EndDate,cruises.Chief_Scientist,cruises.id'
             #select_clause = '*'
             @cruises = reduce_specifics(Cruise.find_by_sql("SELECT DISTINCT #{select_clause} FROM cruises LEFT JOIN parameters ON cruises.ExpoCode = parameters.ExpoCode WHERE #{where_clause} #{@sort_statement}"))
             @table_list = Hash.new{|@table_list,key| @table_list[key]={}}
             @cruise_objects = Array.new
             @cruises.each { |e| @cruise_objects << reduce_specifics(Cruise.find(e.id)) }
             for result in @cruises
                @text = result.ExpoCode
                @dir = Document.find(:first ,:conditions => ["ExpoCode = '#{result.ExpoCode}' and FileType='Directory'"])
                @files_for_expocode = get_files_from_dir(@dir) 
# This code needs to be optimized #############
                if(@dir)
                @cruise_files = Document.find(:all, :conditions => ["ExpoCode = '#{result.ExpoCode}'"])
                @table_list[result.ExpoCode]["Preliminary"] = ""
                 for cruise_file in @cruise_files
                   if cruise_file.Preliminary == 1
                     @files_for_expocode["Preliminary"] = "Preliminary (See <a href=\"http://cchdo.ucsd.edu/data_history?ExpoCode=#{result.ExpoCode}\">data history</a>)"
                   end
                 end
                end
###############################################
                cruise_parameters = BottleDB.find(:first, :conditions => ["ExpoCode = '#{result.ExpoCode}'"])
                 @param_list[result.ExpoCode]['stations'] = 0
                 @param_list[result.ExpoCode]['parameters']= ""
                 param_list = ""
                 if cruise_parameters
                    @param_list[result.ExpoCode]['stations'] = cruise_parameters.Stations
                    if cruise_parameters.Parameters =~ /\w/
                      param_list = cruise_parameters.Parameters
                      param_persistance = cruise_parameters.Parameter_Persistance

                      @param_list[result.ExpoCode]['parameters'] = param_list#.split(',')
                      param_array = param_list.split(',')
                      persistance_array = param_persistance.split(',')
                      for ctr in 1..param_array.length
                        @param_list[result.ExpoCode]["#{param_array[ctr]}"]  = persistance_array[ctr]
                      end
                    end
                 end # if cruise_parameters
                @table_list[result.ExpoCode] = @files_for_expocode
             end #for result in @best_result
          end# if @best_result.keys.length > 0
       end #   if @query =~ /\w/
    end#   if(params[:query])
  end
  
  # deprecated
  def find_cruises(query, skip=0, limit=nil, count=false)
     best_queries, param_queries = best_query_type(query)

     # Build SQL query
     where_clauses = Array.new
     limit_clause = (limit && "LIMIT #{skip}, #{limit}") || ''

     if best_queries
       best_queries.each_pair do |type, query|
         if type == 'All'
           skip = 0
           limit = 0
           limit_clause = ''
         elsif type == 'Date'
           where_clauses << "(Begin_Date REGEXP '#{query}' OR EndDate REGEXP '#{query}')"
         # Also search for aliases that look like lines
         elsif type == 'Line'
           where_clauses << "#{type} REGEXP '#{query}' OR Alias REGEXP '#{query}'"
         elsif type =~ /\byear.?start/ # \b to keep from grabbing file_year_start too
           required_others = ['year_end', 'month_start', 'month_end']
           other_types = best_queries.keys
           if required_others == required_others & other_types
             begin_date = "#{sprintf("%04u", best_queries['year_start'])}-#{sprintf("%02u", best_queries['month_start'])}-00"
             end_date   = "#{sprintf("%04u", best_queries['year_end'])}-#{sprintf("%02u", best_queries['month_end'])}-00"
             where_clauses << "(\"#{begin_date}\" < Begin_Date AND Begin_Date < \"#{end_date}\")"
           end
         elsif type =~ /(year_end)|(month_start)|(month_end)|(file_month_start)|(file_year_start)|(FileType)/i
           # ignore these (already handled or not handling)
         else
           if type == 'ExpoCode'
             type = 'cruises.ExpoCode'
           end
           where_clauses << "#{type} REGEXP '#{query}'"
         end
       end
     end

     param_queries.each do |parameter|
       where_clauses << "parameters.`#{parameter}` > 0"
     end

     # join them all together
     where_clause = ''
     if wheres = where_clauses.join(' AND ') and not wheres.empty?
       where_clause = "WHERE #{wheres}"
     end

     join_on = ''
     unless param_queries.empty?
       join_on = 'LEFT JOIN (parameters) ON (cruises.ExpoCode=parameters.ExpoCode)'
     end

     cruises = reduce_specifics(Cruise.find_by_sql("SELECT DISTINCT * FROM cruises #{join_on} #{where_clause} #{limit_clause}"))
     if count
       # Hopefully we can make expocodes indexed in the future
       return cruises, best_queries, Cruise.count_by_sql("SELECT count(cruises.id) FROM cruises #{join_on} #{where_clause}")
     else
       return cruises, best_queries
     end
   end

   def parse_query_string(query_str)
     # There must be words in a query
     if query_str !~ /\w/
       return nil
     end

     # Erase illegal characters
     query_str = query_str.strip.tr(";'$%&*()<>/@~`+=#?|{}[]", '.')

     # Get the literals and replace them with place holders
     literals = query_str.scan(/".*?"/)
     literals.each {|literal| query_str.gsub!(literal, '?')}
     literals.map! {|query| query[1..-2]}

     # Make all keyworded queries one chunk
     query_str.gsub!(/\:\s*/, ':')

     # All spaces are now delimiters
     query_str.gsub!(/\s+/, ';')

     # Delete all keywords without values
     query_str.gsub!(/\w+\:;/, '')

     # Get all the terms
     terms = query_str.split(';')

     # Fill in all place holders; they are in order of appearance
     count = 0
     terms.each do |term|
       if term.include? '?'
         term.gsub!('?', literals[count])
         count += 1
       end
     end
     return terms
   end

   def find_best_query(query)
     best = ''
     cur_max = 0
     Cruise.column_names.each do |column|
       if column !~ /(14C)|(id)/
         if column == 'Group'
           column = "`#{column}`"
         end
         num_matches = Cruise.count(:all, :conditions => ["#{column} REGEXP '#{query}'"])
         if num_matches > cur_max
           best = column
           cur_max = num_matches
         end
       end
     end
     return best
   end

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

   # This function returns a hash of short file name to file path
   def get_files_from_dir(dir)
       @file_result = Hash.new
       unless dir
           return @file_result
       end

       @files = dir.Files.split(/\s/)
       trash, path = dir.FileName.split(/data/)
       unless @files
           return @file_result
       end

       for file in @files
          unless file
              continue
          end
          if file =~ /\*$/
             file.chop!
          end
          key = case file
              when /su.txt$/ then 'woce_sum'
              when /ct.zip/  then 'woce_ctd'
              when /hy.txt/  then 'woce_bot'
              when /hy1.csv/ then 'exchange_bot'
              when /ct1.zip/ then 'exchange_ctd'
              when /ctd.zip/ then 'netcdf_ctd'
              when /hyd.zip/ then 'netcdf_bot'
              when /do.txt/  then 'text_doc'
              when /do.pdf/  then 'pdf_doc'
              when /.gif/    then 'big_pic'
              when /.jpg/    then 'small_pic'
              else nil
          end
          if key
              @file_result[key] = "/data#{path}/#{file}"
          end
          @lfile = file
       end

       return @file_result
   end

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
