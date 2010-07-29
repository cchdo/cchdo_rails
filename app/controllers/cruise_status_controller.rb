class CruiseStatusController < ApplicationController
  layout "staff", :except => [:pis_for_lookup]
  before_filter :check_authentication, :except => [:signin, :images, :pis_for_lookup, :ships_for_lookup, :countries_for_lookup,:parameters_for_lookup]
  #cache_sweeper :task_tracker

  def check_authentication
     unless session[:user]

           session[:intended_action] = action_name
        session[:intended_controller] = controller_name
        redirect_to :action => "signin"
     end
  end

  def signin
     if request.post?   

        #session[:user] = User.authenticate(params[:username],params[:password]).id
        user = User.authenticate(params[:username],params[:password])
        if user
           session[:user] = user.id
           redirect_to :action => session[:intended_action],:controller => session[:intended_controller]
        else
           flash[:notice] = "Invalid user name or password"
        end
     end
  end

  def signout
     session[:user] = nil
     redirect_to "http://cchdo.ucsd.edu/"
  end

  def index
     @user = User.find(session[:user])
     @user = @user.username
     cruise_information
     render :action => 'cruise_information'
  end

  def flag_cruises
    @cruise_list = Cruise.find(:all)
    file_result = Hash.new
    missing_all_cruises = Array.new
    missing_some_cruises = Array.new
    for cruise in @cruise_list
      doc = Document.find(:first,:conditions => ["FileType = 'Directory' and ExpoCode = '#{cruise.ExpoCode}'"])
      file_result['woce_sum'] = nil
      file_result['woce_ctd'] = nil
      file_result['woce_bot'] = nil
      file_result['exchange_bot'] = nil
      file_result['exchange_ctd'] = nil
      file_result['netcdf_ctd'] = nil
      file_result['netcdf_bot'] = nil
      file_result['text_doc'] = nil
      file_result['pdf_doc'] = nil
      file_result['big_pic'] = nil
      file_result['small_pic'] = nil
      if(doc)
         @files = doc.Files.split(/\s/)
         trash,path = doc.FileName.split(/data/)
         if @files
            #file_result[expo.ExpoCode] = []
            for file in @files
               if file
                  if(file =~ /\*$/)
                     file.chop!
                  end
                  case file
                     when /su.txt$/ then file_result['woce_sum'] = file
                     when /ct.zip/  then file_result['woce_ctd'] = file
                     when /hy.txt/  then file_result['woce_bot'] = file
                     when /hy1.csv/ then file_result['exchange_bot'] = file
                     when /ct1.zip/ then file_result['exchange_ctd'] = file
                     when /ctd.zip/ then file_result['netcdf_ctd'] = file
                     when /hyd.zip/ then file_result['netcdf_bot'] = file
                     when /do.txt/  then file_result['text_doc'] = file
                     when /do.pdf/  then file_result['pdf_doc'] = file
                     when /.gif/    then file_result['big_pic'] = "#{doc.FileName}/#{file}"
                     when /.jpg/    then file_result['small_pic'] = "/data#{path}/#{file}"
                  end
               end
               @lfile = file
            end #for files in @files
         end #if(@files)
      end #if(@doc)
      missing = nil
      file_ctr =0
      for key in file_result.keys
         if file_result[key]
           file_ctr= file_ctr +1
         end
      end
      if file_ctr == 0
        missing_all_cruises << cruise.ExpoCode
      end
      if file_ctr < 11 and file_ctr != 0
        missing_some_cruises << cruise.ExpoCode
      end
    end
    return missing_all_cruises, missing_some_cruises
  end

  def organize_cruises
    @cruise_list = Cruise.find(:all)
    @cruises_by_group = Hash.new{|@cruises_by_group,key| @cruises_by_group[key]=[]}
    for cruise in @cruise_list
          groups = Array.new
          if group = cruise.Group
            if group =~ /\w/
              groups = group.split(",")
            end
          end
          if groups.length >= 1
            @cruises_by_group[groups[0]] << cruise
          else
            @cruises_by_group['No_Group'] << cruise
          end
    end
    return @cruises_by_group
  end



  def cruise_information
    #@cruises = Cruise.find(:all)
    @val = "Is nothing coming through?"
    @cruises = organize_cruises
    (@no_files_cruises, @some_files_cruises) = flag_cruises
    @file_result = Hash.new
    @file_result['woce_sum'] = nil
    @file_result['woce_ctd'] = nil
    @file_result['woce_bot'] = nil
    @file_result['exchange_bot'] = nil
    @file_result['exchange_ctd'] = nil
    @file_result['netcdf_ctd'] = nil
    @file_result['netcdf_bot'] = nil
    @file_result['text_doc'] = nil
    @file_result['pdf_doc'] = nil
    @file_result['big_pic'] = nil
    @file_result['small_pic'] = nil
    if params[:expo]
      #Data history code ###########
      @note = params[:Note]
      @entry = params[:Entry]
      @cur_sort = params[:Sort]
      #@updated = Event.find_by_sql("SELECT * FROM events ORDER BY Date_Entered DESC LIMIT 1")
      #@updated = Event.find(:first,:order=>'Date_Entered DESC')
         if(@cur_sort == "LastName")
            @events = Event.find(:all,:conditions=>["ExpoCode='#{params[:expo]}'"],:order=>['LastName'])
         elsif( @cur_sort == "Data_Type")
            @events = Event.find(:all,:conditions=>["ExpoCode='#{params[:expo]}'"],:order=>['Data_Type'])
         else
            @events = Event.find(:all,:conditions=>["ExpoCode='#{params[:expo]}'"],:order=>['Date_Entered DESC'])
         end
      if (@note)
         @note_entry = Event.find(:first,:conditions=>["ID=#{@entry}"])
      end
      # Data history code !#############


      @cruise = Cruise.find(:first,:conditions => ["ExpoCode = '#{params[:expo]}'"])
      @doc = Document.find(:first,:conditions => ["FileType = 'Directory' and ExpoCode = '#{params[:expo]}'"])

      if(@doc)
         @files = @doc.Files.split(/\s/)
         trash,path = @doc.FileName.split(/data/)
         if @files
            #file_result[expo.ExpoCode] = []
            for file in @files
               if file
                  if(file =~ /\*$/)
                     file.chop!
                  end
                  case file
                     when /su.txt$/ then @file_result['woce_sum'] = Document.find(:first,:conditions => ["FileType = 'Woce Sum' and ExpoCode = '#{params[:expo]}'"])
                     when /ct.zip/  then @file_result['woce_ctd'] = Document.find(:first,:conditions => ["FileType = 'Woce CTD (Zipped)' and ExpoCode = '#{params[:expo]}'"])
                     when /hy.txt/  then @file_result['woce_bot'] = Document.find(:first,:conditions => ["FileType = 'Woce Bottle' and ExpoCode = '#{params[:expo]}'"])
                     when /hy1.csv/ then @file_result['exchange_bot'] = Document.find(:first,:conditions => ["FileType = 'Exchange Bottle' and ExpoCode = '#{params[:expo]}'"])
                     when /ct1.zip/ then @file_result['exchange_ctd'] = Document.find(:first,:conditions => ["FileType = 'Exchange CTD (Zipped)' and ExpoCode = '#{params[:expo]}'"])
                     when /ctd.zip/ then @file_result['netcdf_ctd'] = Document.find(:first,:conditions => ["FileType = 'NetCDF CTD' and ExpoCode = '#{params[:expo]}'"])
                     when /hyd.zip/ then @file_result['netcdf_bot'] = Document.find(:first,:conditions => ["FileType = 'NetCDF Bottle' and ExpoCode = '#{params[:expo]}'"])
                     when /do.txt/  then @file_result['text_doc'] = Document.find(:first,:conditions => ["FileType = 'Documentation' and ExpoCode = '#{params[:expo]}'"])
                     when /do.pdf/  then @file_result['pdf_doc'] = Document.find(:first,:conditions => ["FileType = 'PDF Documentation' and ExpoCode = '#{params[:expo]}'"])
                     when /.gif/    then @file_result['big_pic'] = "#{@doc.FileName}/#{file}"
                     when /.jpg/    then @file_result['small_pic'] = "/data#{path}/#{file}"
                  end
               end
               @lfile = file
            end #for files in @files
         end #if(@files)
      end #if(@doc)
    else
      @cruise = Cruise.find(:first)
    end

  end

  def note
    @entry = params[:Entry]
    @note_entry = Event.find(:first,:conditions=>["ID=#{@entry}"])
    render :partial => "note"
  end

  def all_cruise_meta
    @file_result = Hash.new
    @file_result['woce_sum'] = nil
    @file_result['woce_ctd'] = nil
    @file_result['woce_bot'] = nil
    @file_result['exchange_bot'] = nil
    @file_result['exchange_ctd'] = nil
    @file_result['netcdf_ctd'] = nil
    @file_result['netcdf_bot'] = nil
    @file_result['text_doc'] = nil
    @file_result['pdf_doc'] = nil
    @file_result['big_pic'] = nil
    @file_result['small_pic'] = nil
    if params[:expo]
      #Data history code ###########
      @note = params[:Note]
      @entry = params[:Entry]
      @cur_sort = params[:Sort]
      #@updated = Event.find_by_sql("SELECT * FROM events ORDER BY Date_Entered DESC LIMIT 1")
      #@updated = Event.find(:first,:order=>'Date_Entered DESC')
         if(@cur_sort == "LastName")
            @events = Event.find(:all,:conditions=>["ExpoCode='#{params[:expo]}'"],:order=>['LastName'])
         elsif( @cur_sort == "Data_Type")
            @events = Event.find(:all,:conditions=>["ExpoCode='#{params[:expo]}'"],:order=>['Data_Type'])
         else
            @events = Event.find(:all,:conditions=>["ExpoCode='#{params[:expo]}'"],:order=>['Date_Entered DESC'])
         end
      if (@note)
         @note_entry = Event.find(:first,:conditions=>["ID=#{@entry}"])
      end
      # Data history code !#############


      @cruise = Cruise.find(:first,:conditions => ["ExpoCode = '#{params[:expo]}'"])
      @doc = Document.find(:first,:conditions => ["FileType = 'Directory' and ExpoCode = '#{params[:expo]}'"])

      if(@doc)
         @files = @doc.Files.split(/\s/)
         trash,path = @doc.FileName.split(/data/)
         if @files
            #file_result[expo.ExpoCode] = []
            for file in @files
               if file
                  if(file =~ /\*$/)
                     file.chop!
                  end
                  case file
                     when /su.txt$/ then @file_result['woce_sum'] = Document.find(:first,:conditions => ["FileType = 'Woce Sum' and ExpoCode = '#{params[:expo]}'"])
                     when /ct.zip/  then @file_result['woce_ctd'] = Document.find(:first,:conditions => ["FileType = 'Woce CTD (Zipped)' and ExpoCode = '#{params[:expo]}'"])
                     when /hy.txt/  then @file_result['woce_bot'] = Document.find(:first,:conditions => ["FileType = 'Woce Bottle' and ExpoCode = '#{params[:expo]}'"])
                     when /hy1.csv/ then @file_result['exchange_bot'] = Document.find(:first,:conditions => ["FileType = 'Exchange Bottle' and ExpoCode = '#{params[:expo]}'"])
                     when /ct1.zip/ then @file_result['exchange_ctd'] = Document.find(:first,:conditions => ["FileType = 'Exchange CTD (Zipped)' and ExpoCode = '#{params[:expo]}'"])
                     when /ctd.zip/ then @file_result['netcdf_ctd'] = Document.find(:first,:conditions => ["FileType = 'NetCDF CTD' and ExpoCode = '#{params[:expo]}'"])
                     when /hyd.zip/ then @file_result['netcdf_bot'] = Document.find(:first,:conditions => ["FileType = 'NetCDF Bottle' and ExpoCode = '#{params[:expo]}'"])
                     when /do.txt/  then @file_result['text_doc'] = Document.find(:first,:conditions => ["FileType = 'Documentation' and ExpoCode = '#{params[:expo]}'"])
                     when /do.pdf/  then @file_result['pdf_doc'] = Document.find(:first,:conditions => ["FileType = 'PDF Documentation' and ExpoCode = '#{params[:expo]}'"])
                     when /.gif/    then @file_result['big_pic'] = "#{@doc.FileName}/#{file}"
                     when /.jpg/    then @file_result['small_pic'] = "/data#{path}/#{file}"
                  end
               end
               @lfile = file
            end #for files in @files
         end #if(@files)
      end #if(@doc)
    else
      @cruise = Cruise.find(:first)
    end
    render :partial => "all_cruise_meta"
  end

end
