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
            cruises = reduce_specifics(Cruise.find(:all,:conditions => ["`Group` regexp ?", group]))
            if @cruise_groups
               @cruise_groups << cruises
            else
               @cruise_groups[0] = cruises
            end
         end
      end

      @cruise.Chief_Scientist = @cruise.chisci_to_links()

      @file_result = @cruise.get_files()
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

   def list_cruises
       redirect_to search_path
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

end
