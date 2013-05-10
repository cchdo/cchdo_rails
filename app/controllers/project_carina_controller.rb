class ProjectCarinaController < ApplicationController
layout "carina"
  def index
    if params[:sort]
      @sort = params[:sort]
      @sort_name =  case @sort
         when  "Ship_Name" : "Ship"
         when  "Begin_Date" : "Year"
         when "Country": "Country"
         when "ExpoCode": "ExpoCode"
      end
        
    else
      @sort = "Ship_Name"
      @sort_name = "Ship"
    end
    if @sort 
      @cruises = CarinaCruise.find(:all,:order => "#{@sort}") 
    else
      @cruises = CarinaCruise.find(:all)
    end
    reduce_specifics(@cruises)
    @file_result = Hash.new
    @table_list = Hash.new{|@table_list,k| @table_list[k]={}}
    ctr = 0
    for cruise in @cruises

        
        if cruise.ExpoCode =~ /\w/
           # Collect Bottle, CTD, Document file info
            @dir = CarinaDocument.find(:first ,:conditions => ["`ExpoCode` = '#{cruise.ExpoCode}' and `FileType` = 'Directory'"])
            @data_history_entries = CarinaEvent.find(:all,:conditions => ["`ExpoCode` = '#{cruise.ExpoCode}'"])
            @table_list[cruise.ExpoCode]['events'] = @data_history_entries.length
            if cruise.CCHDO_Copied.eql?(1)
              @table_list[cruise.ExpoCode]["Copied"] = 1
            else
              @table_list[cruise.ExpoCode]["Copied"] = 0
            end
            if cruise.Country =~ /\w/ 
              if COUNTRIES.values.include?(cruise.Country.downcase.strip)

                cruise.Country = COUNTRIES.invert[cruise.Country.downcase].capitalize
                if cruise.Country =~ /\s/
                  @temp_string = cruise.Country.split
                  @temp_string.map!{|e| e.capitalize}
                  cruise.Country = @temp_string.join(' ')
                end
                if cruise.Country =~ /^usa$/i or cruise.Country =~ /^us$/i
                  cruise.Country = "USA"
                end
              end
            end
            @dirt = "`ExpoCode` = '#{cruise.ExpoCode}' and `FileType` = 'Directory'"
            if(@dir)
              @cruise_files = CarinaDocument.find(:all, :conditions => ["ExpoCode = '#{cruise.ExpoCode}'"])
              @table_list[cruise.ExpoCode]["Preliminary"] = ""
               for cruise_file in @cruise_files
                 if cruise_file.Preliminary == 1
                   @table_list[cruise.ExpoCode]["Preliminary"] = "Preliminary (See <a href=\"http://cchdo.ucsd.edu/cruise/#{cruise.ExpoCode}#history\">data history</a>)"
                 end
               end
               @files = @dir.Files.split(/\s/)
               trash,path = @dir.FileName.split(/data/)
               if @files
                  for file in @files
                     if file
                        if(file =~ /\*$/)
                           file.chop!
                        end
                        case file
                           when /su.txt$/ then @table_list[cruise.ExpoCode]['woce_sum'] = "/data#{path}/#{file}"
                           when /lv.txt/  then @table_list[cruise.ExpoCode]['large_volume'] = "/data#{path}/#{file}"
                           when /lvs.txt/ then @table_list[cruise.ExpoCode]['large_volume'] = "/data#{path}/#{file}"
                           when /hy1.csv/ then @table_list[cruise.ExpoCode]['exchange_bot'] = "/data#{path}/#{file}"
                           when /ct1.zip/ then @table_list[cruise.ExpoCode]['exchange_ctd'] = "/data#{path}/#{file}"
                           when /do.pdf/  then @table_list[cruise.ExpoCode]['pdf_doc'] = "/data#{path}/#{file}"
                           when /.gif/    then @table_list[cruise.ExpoCode]['map'] = "/data#{path}/#{file}"
                           when /.jpg/    then @table_list[cruise.ExpoCode]['small_pic'] = "/data#{path}/#{file}"
                           when /ct.zip/  then @table_list[cruise.ExpoCode]['woce_ctd'] = "/data#{path}/#{file}"
                           when /hy.txt/  then @table_list[cruise.ExpoCode]['woce_bot'] = "/data#{path}/#{file}"
                           when /ctd.zip/ then @table_list[cruise.ExpoCode]['netcdf_ctd'] = "/data#{path}/#{file}"
                           when /hyd.zip/ then @table_list[cruise.ExpoCode]['netcdf_bot'] = "/data#{path}/#{file}"
                           when /do.txt/  then @table_list[cruise.ExpoCode]['text_doc'] = "/data#{path}/#{file}"
                        end
                     end #if file
                     @lfile = file
                  end # for file in @files
               end # if @files
            end # if @dir
            
           ctr+= 1
        end # if cruise.ExpoCode
     end # for cruise in @cruises
    
  end
  
  def sort
     if params[:sort]
        @sort = params[:sort]
        @sort_name =  case @sort
        when  "Ship_Name" : "Ship"
        when  "Begin_Date" : "Year"
        when "Country": "Country"
        when "ExpoCode": "ExpoCode"
        end

      else
        @sort = "Ship_Name"
        @sort_name = "Ship"
      end
      if params[:order]
        @order = params[:order]
      else
        @order = ""
      end
      if @sort 
        @cruises = CarinaCruise.find(:all,:order => "#{@sort} #{@order}") 
      else
        @cruises = CarinaCruise.find(:all)
      end
      reduce_specifics(@cruises)
      @file_result = Hash.new
      @table_list = Hash.new{|@table_list,k| @table_list[k]= Hash.new(0)}
      ctr = 0
      for cruise in @cruises


          if cruise.ExpoCode =~ /\w/
             # Collect Bottle, CTD, Document file info
              @dir = CarinaDocument.find(:first ,:conditions => ["`ExpoCode` = '#{cruise.ExpoCode}' and `FileType` = 'Directory'"])
              @data_history_entries = CarinaEvent.find(:all,:conditions => ["`ExpoCode` = '#{cruise.ExpoCode}'"])
              @table_list[cruise.ExpoCode]['events'] = @data_history_entries.length
            if cruise.CCHDO_Copied.eql?(1)
              @table_list[cruise.ExpoCode]["Copied"] = 1
            else
              @table_list[cruise.ExpoCode]["Copied"] = 0
            end
              if cruise.Country =~ /\w/ 
                if COUNTRIES.values.include?(cruise.Country.downcase.strip)

                  cruise.Country = COUNTRIES.invert[cruise.Country.downcase].capitalize
                  if cruise.Country =~ /\s/
                    @temp_string = cruise.Country.split
                    @temp_string.map!{|e| e.capitalize}
                    cruise.Country = @temp_string.join(' ')
                  end
                  if cruise.Country =~ /^usa$/i or cruise.Country =~ /^us$/i
                    cruise.Country = "USA"
                  end
                end
              end
              @dirt = "`ExpoCode` = '#{cruise.ExpoCode}' and `FileType` = 'Directory'"
              if(@dir)
                @cruise_files = CarinaDocument.find(:all, :conditions => ["ExpoCode = '#{cruise.ExpoCode}'"])
                @table_list[cruise.ExpoCode]["Preliminary"] = ""
                 for cruise_file in @cruise_files
                   if cruise_file.Preliminary == 1
                     @table_list[cruise.ExpoCode]["Preliminary"] = "Preliminary (See <a href=\"http://cchdo.ucsd.edu/cruise/#{cruise.ExpoCode}#history\">data history</a>)"
                   end
                 end
                 @files = @dir.Files.split(/\s/)
                 trash,path = @dir.FileName.split(/data/)
                 if @files
                    for file in @files
                       if file
                          if(file =~ /\*$/)
                             file.chop!
                          end
                          case file
                             when /su.txt$/ then @table_list[cruise.ExpoCode]['woce_sum'] = "/data#{path}/#{file}"
                             when /lv.txt/  then @table_list[cruise.ExpoCode]['large_volume'] = "/data#{path}/#{file}"
                             when /lvs.txt/ then @table_list[cruise.ExpoCode]['large_volume'] = "/data#{path}/#{file}"
                             when /hy1.csv/ then @table_list[cruise.ExpoCode]['exchange_bot'] = "/data#{path}/#{file}"
                             when /ct1.zip/ then @table_list[cruise.ExpoCode]['exchange_ctd'] = "/data#{path}/#{file}"
                             when /.pdf/  then @table_list[cruise.ExpoCode]['pdf_doc'] = "/data#{path}/#{file}"
                             when /.gif/    then @table_list[cruise.ExpoCode]['map'] = "/data#{path}/#{file}"
                             when /.jpg/    then @table_list[cruise.ExpoCode]['small_pic'] = "/data#{path}/#{file}"
                             when /ct.zip/  then @table_list[cruise.ExpoCode]['woce_ctd'] = "/data#{path}/#{file}"
                             when /hy.txt/  then @table_list[cruise.ExpoCode]['woce_bot'] = "/data#{path}/#{file}"
                             when /ctd.zip/ then @table_list[cruise.ExpoCode]['netcdf_ctd'] = "/data#{path}/#{file}"
                             when /hyd.zip/ then @table_list[cruise.ExpoCode]['netcdf_bot'] = "/data#{path}/#{file}"
                             when /do.txt/  then @table_list[cruise.ExpoCode]['text_doc'] = "/data#{path}/#{file}"
                          end
                       end #if file
                       @lfile = file
                    end # for file in @files
                 end # if @files
              end # if @dir

             ctr+= 1
          end # if cruise.ExpoCode
       end # for cruise in @cruises
    
    render :partial => "full_results"
  end
  
  def sort_by_ship
    @cruises = CarinaCruise.find(:all,:order => ["Ship_Name"]) 
    reduce_specifics(@cruises)
    params[:current_tab] = "ship_tab"
    render :partial => "sort_by_ship"
    

    
  end
  
  def show_files
    expo = params[:expo]
    @file_result = Hash.new
    @dir = CarinaDocument.find(:first ,:conditions => ["ExpoCode = '#{expo}' and FileType='Directory'"])
    @files = @dir.Files.split(/\s/)
    trash,path = @dir.FileName.split(/data/)
    if @files
       for file in @files
          if file
             if(file =~ /\*$/)
                file.chop!
             end
             case file
                when /hy1.csv/ then @file_result['exchange_bot'] = "/data#{path}/#{file}"
                when /ct1.zip/ then @file_result['exchange_ctd'] = "/data#{path}/#{file}"
                when /do.txt/  then @file_result['text_doc'] = "/data#{path}/#{file}"
                when /do.pdf/  then @file_result['pdf_doc'] = "/data#{path}/#{file}"
                when /.gif/    then @file_result['small_pic'] = "/data#{path}/#{file}"
                when /.jpg/    then @file_result['big_pic'] = "/data#{path}/#{file}"
             end
          end
       end
    end
    render :partial => "show_files"
  end
  
  def sort_by_year
    @cruises = CarinaCruise.find(:all, :order => ["Begin_Date"])
    params[:current_tab] = "year_tab"
    render :partial => "sort_by_year"
  end  
  
  def sort_by_country
    @cruises = CarinaCruise.find(:all, :order => ["Country"])
    params[:current_tab] = "country_tab"
    render :partial => "sort_by_country"
  end
  
end
