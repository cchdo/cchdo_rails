class ExpoDate
    attr_reader :expo, :date
    def initialize(expo, date)
        @expo = expo
        @date = date
    end
end


class DataAccessController < ApplicationController
    layout 'standard', :except => :feed

    def index
        expo = params[:ExpoCode]
        if expo
            redirect_to :action => 'show_cruise', :ExpoCode => expo
        else
            redirect_to :action => 'advanced_search'
        end
    end

    # GET /feed/:expocodes/as.atom
    # Params:
    #   expocodes - comma separated list of expocodes
    def feed
        expocodes = params[:expocodes].split(',')
        expocodes = [expocodes] unless expocodes.kind_of?(Array)

        @header = []
        @updates = []
        for expocode in expocodes
            @updates += Document.get_feed_documents_for(expocode)
            @updates += Event.get_feed_events_for(expocode)
            @header << "(#{@updates.last.cruise.Line}) #{expocode}"
        end

        @header = @header.join(',')

        @updates.sort do |a, b|
            a.feed_datetime() <=> b.feed_datetime()
        end

        respond_to do |format|
            format.atom
        end
    end

    def convert_chisci_to_links(cruise)
        # Regular expression for exctracting multiple names from Chief_Scientist
        if not cruise.Chief_Scientist
            return
        end
        pi_names = cruise.Chief_Scientist.scan( /([a-z]+)\/?\\?([a-z]*):?\/?([a-z]*)\/?\\?([a-z]*)/i)
        #Substitute name matches for links to the contact's page
        #if @pi_names.length > 1
        for group in pi_names
            for name in group
                # This says Dickson, MAFF, , . I don't know what's up with the extra empty string entries.
                RAILS_DEFAULT_LOGGER.warn("#{name} is in #{group} in #{pi_names}")

                if pi_found = Contact.find_by_LastName(name)
                    cruise.Chief_Scientist.sub!(/(#{name})/,"<a href=\'contact?contact=#{name}\'>#{name}</a>")
                end
            end
        end
    end

   def show_cruise
      return if params[:commit] =~ /Cruises/ or params[:commit] =~ /Files/

      @expo = params[:ExpoCode] || params[:expocode]
      return unless @expo

      @cruise = reduce_specifics(Cruise.find_by_ExpoCode(@expo))
      return if not @cruise

      @preliminary = ""

      @cruise_groups = Array.new
      if @groups = @cruise.Group
         @groups = @groups.split(',')
      else
         @groups = []
      end
      for group in @groups
         if group =~ /\w/
            cruises = reduce_specifics(Cruise.find(:all,:conditions => ["`Group` regexp '#{group}'"]))
            if @cruise_groups
               @cruise_groups << cruises
            else
               @cruise_groups[0] = cruises
            end
         end
      end

      convert_chisci_to_links(@cruise)

      @dir = Document.find_by_ExpoCode_and_FileType(@cruise.ExpoCode, 'Directory')
      @file_result = get_files_from_dir(@dir)
      @preliminary = preliminary_message(@cruise)

      @queue_files = QueueFile.all(
        :conditions => {:ExpoCode => @expo, :Merged => false})
      @merged_queue_files = QueueFile.all(
        :conditions => {:ExpoCode => @expo, :Merged => true},
        :order => ['DateMerged DESC, DateRecieved DESC'])
      @support_files = SupportFile.find(
        :all, :conditions => {:ExpoCode => @expo})

      sort_hist = params[:sort_history]
      if sort_hist == "person"
          sort_column = 'LastName'
      elsif sort_hist == "action"
          sort_column = 'Action'
      elsif sort_hist == "summary"
          sort_column = 'Summary'
      elsif sort_hist == "data_type"
          sort_column = 'Data_Type'
      else
          sort_column = 'Date_Entered DESC'
      end
      @events = Event.find(
        :all, :conditions => {:ExpoCode => @expo}, :order => [sort_column])

      if params[:Note] and params[:Entry]
         @note = params[:Note]
         @entry = params[:Entry]

         @note_entry = Event.find_by_ID(@entry)
         @note_entry[:Note].gsub!(/[\n\r\f]/,"<br>")
         @note_entry[:Note].gsub!(/[\t]/,"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")
      else
         @note = nil
      end
   end

   # deprecated search functionality?
   def list_cruises
      @param_list = Hash.new{|h,k| h[k]={}}

      @parameters = params
      if params[:expanded]
        @expanded = true
      end

      @t = ""
      @query_mem = ""
      @parameters.each_pair{ |key,value| 
          unless key == 'expanded'
              @query_mem << "#{key}=#{value}&"
          end
          if(key != "commit" and
             key != "YEARSTART" and
             key != "MONTHSTART" and
             key != "YEAREND" and
             key != "MONTHEND" and
             key != "post" and
             key != "action" and
             key != "controller" and
             key != "expanded" and
             key !~ /Type/ and
             key != "Sort" and
             value =~ /\w/
            )
              if(@search_expression)
                  @search_expression << " AND #{key} REGEXP \"#{value}\""
              else
                  @search_expression = "#{key} REGEXP \"#{value}\""
              end
          end
      }
      @query_mem.gsub!(/\s/,'+')
      @expanded_link = "data_access/list_cruises?#{@query_mem}"
      @condensed_link = "data_access/list_cruises?#{@query_mem}"
      @query_link = "data_access/list_cruises?#{@query_mem}"
      @query_with_sort_link = "#{@query_link}"
      @sort_statement = ""
      @sort_check = ["Line","ExpoCode","Begin_Date","Ship_Name","Chief_Scientist","Country"]
      if params[:Sort]
        @sort_by = params[:Sort]
        if @sort_check.include?(@sort_by)
          @sort_statement = "ORDER BY #{@sort_by}"
          @query_with_sort_link << "&Sort=#{@sort_by}"
        end
      end
      if(@parameters[:YEARSTART] and @parameters[:YEAREND] and @parameters[:MONTHSTART] and @parameters[:YEAREND])
         begin_date = "#{@parameters[:YEARSTART]}-#{@parameters[:MONTHSTART]}-01"
         end_date   =  "#{@parameters[:YEAREND]}-#{@parameters[:MONTHEND]}-01"
         unless begin_date.eql?(end_date)
           if(@search_expression)
               @search_expression << " AND Begin_Date > \"#{begin_date}\" AND Begin_Date < \"#{end_date}\""
           else
              @search_expression = "Begin_Date > \"#{begin_date}\" AND Begin_Date < \"#{end_date}\""
           end
         end
      end
      if (@search_expression )
         @cruises = reduce_specifics(Cruise.find_by_sql("SELECT DISTINCT ExpoCode,Line,Country,Ship_Name,Chief_Scientist,Begin_Date,EndDate,Alias,id From cruises where #{@search_expression} #{@sort_statement}"))
         @cruise_objects = Array.new
         @cruises.each { |e| @cruise_objects << reduce_specifics(Cruise.find(e.id)) }
         @file_hash = Hash.new{|@file_hash,key| @file_hash[key]={}}

         @table_list = Hash.new{|@table_list,key| @table_list[key]={}}

         for result in @cruises
            convert_chisci_to_links(result)
            expo = result.ExpoCode
            @table_list[expo], @param_list[expo] = load_files_and_params(result)
         end
      end #if(@search_expression)
      render 'search/index',:layout => true
   end

   def list_files
      @paramerters = params
      if params[:FileType] =~ /\w/
         file_type = params[:FileType]
         @expos = Array.new(0)
         @changed_sets = Hash.new{|@changed_sets,key| @changed_sets[key]={}}
         @expo_dates = Array.new
         @begin_date = "#{@paramerters[:YEARSTART]}-#{@paramerters[:MONTHSTART]}-01"
         case file_type
            when /all/ then @file_expression = "(FileType regexp 'Sum' or FileType regexp 'Bottle' or FileType regexp 'CTD' or FileType regexp 'Documentation') and (documents.ExpoCode = cruises.ExpoCode)"
            when /bottle/  then @file_expression = "(FileType regexp 'Bottle' and cruises.ExpoCode = documents.ExpoCode)"
            when /sum/  then @file_expression = "(FileType regexp 'Sum' and cruises.ExpoCode = documents.ExpoCode)"
            when /ctd/  then @file_expression = "(FileType regexp 'CTD' and cruises.ExpoCode = documents.ExpoCode)"
            when /documentation/  then @file_expression = "(FileType regexp 'Documentation' and cruises.ExpoCode = documents.ExpoCode)"
         end
         if(@file_expression)
            @file_expression << " AND documents.LastModified > \"#{@begin_date}\""
            @files = Document.find_by_sql("SELECT distinct documents.FileName,documents.ExpoCode,documents.LastModified,cruises.Line,cruises.Ship_Name,cruises.Country,cruises.Begin_Date,cruises.EndDate from cruises,documents where #{@file_expression}")
            file_path = Array.new
            for file in @files

               unless @expos.include? file.ExpoCode
                 @expos << file.ExpoCode
                 @changed_sets[file.ExpoCode]["Files"] = String.new
                 @changed_sets[file.ExpoCode]["EarliestDate"] = Time.now
               end
               #file_path = file.FileName.split(/\//)
               #file.FileName = file_path[file_path.length-1]
               cur_date = nil
               case file.FileName
                   when /su.txt$/ then @changed_sets[file.ExpoCode]['woce_sum'] = file.FileName
                                       @changed_sets[file.ExpoCode]['woce_sum_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /ct.zip/  then @changed_sets[file.ExpoCode]['woce_ctd'] = file.FileName
                                        @changed_sets[file.ExpoCode]['woce_ctd_date'] = file.LastModified
                                        cur_date = file.LastModified.to_s
                   when /hy.txt/  then @changed_sets[file.ExpoCode]['woce_bot'] = file.FileName
                                       @changed_sets[file.ExpoCode]['woce_bot_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /lv.txt/  then @changed_sets[file.ExpoCode]['large_volume'] = file.FileName
                                       @changed_sets[file.ExpoCode]['large_volume_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /lvs.txt/  then @changed_sets[file.ExpoCode]['large_volume'] = file.FileName
                                       @changed_sets[file.ExpoCode]['large_volume_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /hy1.csv/ then @changed_sets[file.ExpoCode]['exchange_bot'] = file.FileName
                                       @changed_sets[file.ExpoCode]['exchange_bot_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /ct1.zip/ then @changed_sets[file.ExpoCode]['exchange_ctd'] = file.FileName
                                       @changed_sets[file.ExpoCode]['exchange_ctd_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /ctd.zip/ then @changed_sets[file.ExpoCode]['netcdf_ctd'] = file.FileName
                                       @changed_sets[file.ExpoCode]['netcdf_ctd_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /hyd.zip/ then @changed_sets[file.ExpoCode]['netcdf_bot'] = file.FileName
                                       @changed_sets[file.ExpoCode]['netcdf_bot_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /do.txt/  then @changed_sets[file.ExpoCode]['text_doc'] = file.FileName
                                       @changed_sets[file.ExpoCode]['text_doc_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /do.pdf/  then @changed_sets[file.ExpoCode]['pdf_doc'] = file.FileName
                                       @changed_sets[file.ExpoCode]['pdf_doc_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /.gif/    then @changed_sets[file.ExpoCode]['small_pic'] = file.FileName
                                       @changed_sets[file.ExpoCode]['small_pic_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
                   when /.jpg/    then @changed_sets[file.ExpoCode]['big_pic'] = file.FileName
                                       @changed_sets[file.ExpoCode]['big_pic_date'] = file.LastModified
                                       cur_date = file.LastModified.to_s
               end
               if cur_date
                  file_time = Time.parse(cur_date)
                  if file_time <  @changed_sets[file.ExpoCode]['EarliestDate']
                    @changed_sets[file.ExpoCode]['EarliestDate'] = file_time
                  end
               end
               #@changed_sets[file.ExpoCode]["Files"] << "#{file.FileName}, "
               @changed_sets[file.ExpoCode]["Line"]  = file.Line
               @changed_sets[file.ExpoCode]["Country"] = file.Country
               @changed_sets[file.ExpoCode]["Ship_Name"] = file.Ship_Name
               @changed_sets[file.ExpoCode]["Begin_Date"] = file.Begin_Date
               @changed_sets[file.ExpoCode]["End_Date"] = file.EndDate
               #@changed_sets[file.ExpoCode]["LastModified"] = file.LastModified
               
            end # for file in @files
            @expos.uniq!
         end # if(@file_expression)

         if @expos and @changed_sets
           for expo in @expos
             temp_exp = ExpoDate.new(expo,@changed_sets[expo]['EarliestDate'])
             @expo_dates << temp_exp
           end
           @expo_dates.sort!{|a,b| date_sort(a.date,b.date)}
         end

       end #if params[:FileType] =~ /\w/
   end

    def history
        @expo = params[:ExpoCode]
        @note = params[:Note]
        @entry = params[:Entry]
        @cur_sort = params[:Sort]
        @updated = Event.find_by_sql("SELECT * FROM events ORDER BY Date_Entered DESC LIMIT 1")
        #@updated = Event.find(:first,:order=>'Date_Entered DESC')
        if (@expo)
           if(@cur_sort == "LastName")
              @events = Event.find(:all,:conditions=>["ExpoCode='#{@expo}'"],:order=>['LastName'])
           elsif( @cur_sort == "Data_Type")
              @events = Event.find(:all,:conditions=>["ExpoCode='#{@expo}'"],:order=>['Data_Type'])
           else
              @events = Event.find(:all,:conditions=>["ExpoCode='#{@expo}'"],:order=>['Date_Entered DESC'])
           end
          # @cruise = reduce_specifics(Cruise.find(:first,:conditions=>["ExpoCode='#{@expo}'"]))
        end
        if (@note)
           @note_entry = Event.find(:first,:conditions=>["ID=#{@entry}"])
           @note_entry[:Note].gsub!(/[\n\r\f]/,"<br>")
           @note_entry[:Note].gsub!(/[\t]/,"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")
        end
     end

     def note
       @entry = params[:Entry]
       @note_entry = Event.find(:first,:conditions=>["ID=#{@entry}"])
       render :partial => "note"
     end

   def date_sort(a,b)
     if a < b
       ret_val = -1
     elsif a > b
       ret_val = 1
     else
       ret_val = 0
     end
     return(ret_val)
   end

   def advanced_search
   end

   def pis_for_lookup
   	@pis = Cruise.find(:all,:select => ["DISTINCT Chief_Scientist"])
   	headers['content-type'] = 'text/javascript'
	
	# make things easier for the browser
	str = "var pis = ["
	@pis.each do |pi|
		str += "\"#{pi.Chief_Scientist}\","
	end
	str = str[0..-2] + "];"
	render :text => "#{str}"
   end

   def expocodes_for_lookup
   	@expocodes = Cruise.find(:all,:select => ["DISTINCT ExpoCode"])
   	headers['content-type'] = 'text/javascript'
	
	# make things easier for the browser
	str = "var expocodes = ["
	@expocodes.each do |expocode|
		str += "\"#{expocode.ExpoCode}\","
	end
	str = str[0..-2] + "];"
	render :text => "#{str}"
   end

   def ships_for_lookup
   	@ships = Cruise.find(:all,:select => ["DISTINCT Ship_Name"])
   	headers['content-type'] = 'text/javascript'
	
	# make things easier for the browser
	str = "var ships = ["
	@ships.each do |ship|
		str += "\"#{ship.Ship_Name}\","
	end
	str = str[0..-2] + "];"
	render :text => "#{str}"
   end

   def countries_for_lookup
   	@countries = Cruise.find(:all,:select => ["DISTINCT Country"])
   	headers['content-type'] = 'text/javascript'
	
	# make things easier for the browser
	str = "var countries = ["
	@countries.each do |country|
		str += "\"#{country.Country}\","
	end
	str = str[0..-2] + "];"
	render :text => "#{str}"
   end
   
   
end
