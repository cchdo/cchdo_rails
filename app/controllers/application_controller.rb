require 'cruise_data_formats'

COUNTRIES = {
   'germany'     => 'ger', 'japan' => 'jpn',
   'france'      => 'fra', 'england' => 'uk',
   'canada'      => 'can', 'us' => 'usa',
   'usa'         => 'usa', 'india' => 'ind',
   'russia'      => 'rus', 'spain' => 'spn',
   'argentina'   => 'arg', 'ukrain' => 'ukr',
   'netherlands' => 'net', 'norway' => 'nor',
   'finland'     => 'fin', 'iceland' => 'ice',
   'australia'   => 'aus', 'chile' => 'chi',
   'new zealand' => 'new', 'taiwan' => 'tai',
   'china'       => 'prc'
}

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
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

    before_filter :setup_datacart

    # Scrub sensitive parameters from your log
    filter_parameter_logging :password, :password_confirmation

    protect_from_forgery

    def signin
        if request.post?
            if user = User.authenticate(params[:username], params[:password])
                session[:user] = user.id
                session[:username] = params[:username]
                intended_path = session[:intended_path] || '/'
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

    def setup_datacart
        begin
            @datacart = session['datacart'] || Datacart.new()
        rescue ActionController::SessionRestoreError
            session.clear()
        end
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
        # WARNING this is not reliable since most datafile operations on
        # Document model rely on the Directory entry's Files list rather than
        # the individual file entries.
        if map = Document.find(:first, :conditions => { :ExpoCode => expocode, :FileType => 'Small Plot'})
          return map.FileName[0..-5]
        end
        return nil
    end

    # Provide the message used to indicate a cruise is preliminary
    def preliminary_message(cruise)
        expo = cruise.ExpoCode
        any_preliminary = Document.exists?(:ExpoCode => expo, :Preliminary => 1)
        if any_preliminary
            "Preliminary (See <a href=\"/cruise/#{expo}#history\">data history</a>)"
        else
            ""
        end
    end

    def load_files_and_params(cruise)
        files_for_expocode = cruise.get_files()
        files_for_expocode["Preliminary"] = preliminary_message(cruise)

        param_for_expocode = {
            'stations' => 0,
            'parameters' => {},
        }
        params = param_for_expocode['parameters']
        cruise_parameters = BottleDB.find_by_ExpoCode(cruise.ExpoCode)
        if cruise_parameters
            param_for_expocode['stations'] = (cruise_parameters.Stations || 0).to_i
            param_list = cruise_parameters.Parameters
            param_persistance = cruise_parameters.Parameter_Persistance
            if param_list =~ /\w/ and param_persistance =~ /\w/
                param_array = param_list.split(',')
                persistance_array = param_persistance.split(',')
                for param, persist in param_array.zip(persistance_array)
                    next if param !~ /\w/
                    next if param =~ /castno|flag|time|expocode|sampno|sect_id|depth|latitude|longitude|stnnbr|btlnbr|date|stations|parameters/i
                    params[param] = persist.to_i
                end
            end
        end
        [files_for_expocode, param_for_expocode]
    end

    def best_cruise_column_for_query(query, col_multiplier)
        cur_max = 0
        best_column = nil
        for column in Cruise.columns
            ncruises = Cruise.count(:all, :conditions => ["`#{column.name}` regexp ?", query])
            multiplier = col_multiplier[column.name] || 1
            if ncruises * multiplier > cur_max
                cur_max = ncruises
                best_column = column.name
            end
        end
        best_column || 'Group'
    end
  
    @@columns = {
        'Group' => 'Group',
        'Chief_scientist' => 'Chief_Scientist',
        'Expocode' => 'ExpoCode',
        'Alias' => 'Alias',
        'Ship_name' => 'Ship_Name',
        'Ship' => 'Ship_Name',
        'Line' => 'Line',
        'Parameter' => 'Parameter',
        'After' => 'after',
        'Before' => 'before',
        'Year_start' => 'year_start',
        'Year_end' => 'year_end',
        'Month_start' => 'month_start',
        'Month_end' => 'month_end'
    }
  
    @@parameter_names = Parameter.columns.map {|col| col.name}.reject do |x|
        x =~ /(^(id|ExpoCode)$|(_PI|_Date)$)/
    end
    @@sortable_columns = [
        "Line", "ExpoCode", "Begin_Date", "Ship_Name", "Chief_Scientist",
        "Country"]
    @@sort_directions = ['ASC', 'DESC']


    def best_queries(queries)
        best_result = {}
        param_queries = []

        date_range = [nil, nil, nil, nil]

        for query in queries
            # Special Case 1: Token Search
            #  associate the query with its requested column
            if query =~ /^([\w-]+)\:\s*([\w-]+)$/
                tok = $1.capitalize
                val = $2
                if @@columns.keys.include?(tok)
                    if tok == 'Parameter'
                        if @@parameter_names.include?(val)
                            param_queries << val
                        else
                            Rails.logger.info("Ignored unknown parameter #{val}")
                        end
                    elsif tok =~ /(Year|Month)_(start|end)/
                        if tok =~ /^Year_/
                            if tok =~ /start$/
                                date_range[0] = val
                            else
                                date_range[1] = val
                            end
                        else
                            if tok =~ /start$/
                                date_range[2] = val
                            else
                                date_range[3] = val
                            end
                        end
                    else 
                        best_result[val] = @@columns[tok]
                    end
                    next
                end
            end
            # Change queries formatted like I9 or A6 to be I09 or A06 and
            # weight heavily toward Group column
            col_multiplier = {
                'Group' => 1
            }
            if query =~ /^([a-zA-Z]{1,3})(\d{1,2})$/i
                if $2.length < 2
                    query = "#{$1}0#{$2}"
                    col_multiplier['Group'] = 100
                else
                    query = "#{$1}#{$2}"
                    col_multiplier['Group'] = 100
                end
            end
            # If the search contains a full country name, replace it with the cchdo
            # country abreviation
            if COUNTRIES.include?(query.downcase)
                query = COUNTRIES[query.downcase]
                best_result[query] = 'Country'
                next
            end
            # Check for four digit year queries
            if query =~ /^\d{4}$/
                ncruises = Cruise.count(:all, :conditions => ['`Begin_Date` REGEXP ?', query])
                if ncruises > 0
                    best_result[query] = 'Date'
                    next
                end
            end
            # Check for parameters
            if @@parameter_names.include?(query)
                param_queries << query
                next
            end

            best_result[query] = best_cruise_column_for_query(query, col_multiplier)
        end
        if date_range.compact.length > 0
            begin
                best_result[Date.new(date_range[0].to_i, date_range[2].to_i).strftime('%F')] = 'after'
            rescue
            end
            begin
                best_result[Date.new(date_range[1].to_i, date_range[3].to_i).strftime('%F')] = 'before'
            rescue
            end
        end
        [best_result, param_queries]
    end

    def find_by_params_query
        query = params[:query]
        return unless query

        @query_link = "search?query=#{query}"
        @query_with_sort_link = @query_link.to_s
        @q_pass = query
        @query = query.upcase.strip
        return unless @query =~ /\w/

        if sort_by = params[:Sort] and @@sortable_columns.include?(sort_by)
            dir = params[:Sort_dir]
            if not dir or not @@sort_directions.include?(dir)
                dir = @@sort_directions[0]
            end
            @sort_statement = "ORDER BY cruises.#{sort_by} #{dir}"
            @query_with_sort_link << "&Sort=#{sort_by}&Sort_dir=#{dir}"
        else
            @sort_statement = ""
        end

        # tokenize query based on whitespace or '/'
        @queries = @query.split(/\s+|\//)
        @best_result, @param_queries = best_queries(@queries)

        Rails.logger.debug(@best_result.inspect)
        Rails.logger.debug(@param_queries.inspect)

        # Build sql query based on best results
        select_columns = [
            'ExpoCode', 'Line', 'Ship_Name', 'Country', 'Begin_Date',
            'EndDate', 'Chief_Scientist', 'id']
        where_clauses = []
        sql_parameters = []
        if @best_result.keys.length <= 0 and @param_queries.length <= 0
            @cruises = []
        else
            select_clause = select_columns.map {|x| "`cruises`.`#{x}`" }.join(',')
            for token in @best_result.keys
                column = @best_result[token]
                if column == 'Date'
                    where_clauses << "(Begin_Date REGEXP ? OR EndDate REGEXP ?)"
                    sql_parameters << token
                    sql_parameters << token
                elsif column == 'after'
                    where_clauses << "Begin_Date > ?"
                    sql_parameters << token
                elsif column == 'before'
                    where_clauses << "EndDate < ?"
                    sql_parameters << token
                else
                    where_clauses << "`cruises`.`#{column}` REGEXP ?"
                    sql_parameters << token
                end
            end
            sql = "SELECT DISTINCT #{select_clause} FROM cruises "
            if @param_queries.length > 0
                for param in @param_queries
                    where_clauses << "`bottle_dbs`.`parameters` LIKE ?"
                    sql_parameters << "%#{param}%"
                end
                sql += "LEFT JOIN bottle_dbs ON cruises.ExpoCode = bottle_dbs.ExpoCode "
            end
            where_clause = where_clauses.join(' AND ')
            sql += "WHERE #{where_clause} #{@sort_statement}"
            @cruises = Cruise.find_by_sql([sql] + sql_parameters)
        end

        @cruises = reduce_specifics(@cruises)
        @table_list = Hash.new{|h,k| h[k]={}}
        @param_list = Hash.new{|h,k| h[k]={}}
        for result in @cruises
            expo = result.ExpoCode
            @table_list[expo], @param_list[expo] = load_files_and_params(result)
        end
        Rails.logger.debug(@param_list.inspect)
    end
  
    # deprecated
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
          best_queries['Group'] = query
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
