class CruiseStatusController < ApplicationController
    layout "staff"
    before_filter :check_authentication, :except => [:signin]

    $file_types = [ 
        ['exchange_bot', 'Exchange Bottle'],
        ['exchange_ctd', 'Exchange CTD'],

        ['woce_sum', 'Sum File'],
        ['woce_bot', 'WOCE Bottle'],
        ['woce_ctd', 'WOCE CTD'],

        ['netcdf_bot', 'NetCDF Bottle'],
        ['netcdf_ctd', 'NetCDF CTD'],

        ['text_doc', 'Text Document'],
        ['pdf_doc', 'PDF Document']
    ]

    $type_to_long_type = {
        'woce_sum' => 'Woce Sum',
        'woce_ctd' => 'Woce CTD (Zipped)',
        'woce_bot' => 'Woce Bottle',
        'exchange_bot' => 'Exchange Bottle',
        'exchange_ctd' => 'Exchange CTD (Zipped)',
        'netcdf_ctd' => 'NetCDF CTD',
        'netcdf_bot' => 'NetCDF Bottle',
        'text_doc' => 'Documentation',
        'pdf_doc' => 'PDF Documentation'
    }

    $allowed_event_sorts = ['LastName', 'Data_Type']

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
        redirect_to "/"
    end

    def index
        @user = User.find(session[:user]).username
        cruise_information()
        render :action => 'cruise_information'
    end

    def _expo_dirs
        docdirs = Document.find(:all, :conditions => {:FileType => 'Directory'})
        expo_dirs = docdirs.reduce({}) {|h, dir| h[dir.ExpoCode] = dir; h }
        return expo_dirs
    end

    def _expo_docs(expocode=nil)
        if expocode
            docs = Document.find_all_by_ExpoCode(expocode)
        else
            docs = Document.find(:all)
        end
        expo_docs = docs.reduce({}) do |h, doc|
            if h[doc.ExpoCode]
                h[doc.ExpoCode][doc.FileType] = doc
            else
                h[doc.ExpoCode] = {doc.FileType => doc}
            end
            h
        end
        return expo_docs
    end

    def _flag_cruises(cruises)
        @cruise_list = cruises
        file_result = {}
        missing_all_cruises = []
        missing_some_cruises = []

        expo_dirs = _expo_dirs()
        expo_docs = _expo_docs()
        for cruise in @cruise_list
            expocode = cruise.ExpoCode
            file_result = _gather_file_result(
                expo_dirs[expocode], expo_docs, expocode)
            missing = nil
            file_ctr = 0
            for key in file_result.keys
                if file_result[key]
                    file_ctr= file_ctr + 1
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

    def _organize_cruises(cruises)
        @cruise_list = cruises
        @cruises_by_group = Hash.new {|h, key| h[key] = [] }
        for cruise in @cruise_list
            groups = []
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
        cruises = Cruise.find(:all)
        @cruises = _organize_cruises(cruises)
        (@no_files_cruises, @some_files_cruises) = _flag_cruises(cruises)
        get_cruise_meta()
    end

    def note
        @entry = params[:Entry]
        @note_entry = Event.find(:first, :conditions=>["ID = ?", @entry])
        render :partial => "note"
    end

    def _gather_file_result(doc_dir, expo_docs, expocode)
        file_result = {}
        $type_to_long_type.keys().each {|k| file_result[k] = nil}
        file_result['big_pic'] = nil
        file_result['small_pic'] = nil

        if doc_dir
            type_docs = expo_docs[expocode]

            files = doc_dir.Files.split(/\s/)
            path = doc_dir.FileName
            for file in files
                next unless file
                if file =~ /\*$/
                    file.chop!
                end

                istype = true
                type = nil

                case file
                when /su.txt$/ then type = 'woce_sum'
                when /ct.zip/  then type = 'woce_ctd'
                when /hy.txt/  then type = 'woce_bot'
                when /hy1.csv/ then type = 'exchange_bot'
                when /ct1.zip/ then type = 'exchange_ctd'
                when /ctd.zip/ then type = 'netcdf_ctd'
                when /hyd.zip/ then type = 'netcdf_bot'
                when /do.txt/  then type = 'text_doc'
                when /do.pdf/  then type = 'pdf_doc'
                when /.gif/    then istype = false; type = 'big_pic'
                when /.jpg/    then istype = false; type = 'small_pic'
                end

                if istype
                    file_result[type] = type_docs[$type_to_long_type[type]]
                else
                    file_result[type] = "#{path}/#{file}"
                end

                @lfile = file
            end
        end
        return file_result
    end

    def get_cruise_meta()
        expocode = params[:expo]
        expo_dirs = _expo_dirs()
        if expocode
            @cruise = Cruise.find_by_ExpoCode(expocode)

            # Get data history
            @note = params[:Note]
            @entry = params[:Entry]
            @cur_sort = params[:Sort]

            order_by = 'Date_Entered DESC'
            if $allowed_event_sorts.include?(@cur_sort)
                order_by = @cur_sort
            end
            @events = Event.find_all_by_ExpoCode(
                expocode, :order => [order_by])

            if @note
                @note_entry = Event.find_by_ID(@entry)
            end
        else
            # If no cruise is specified, set up the view for the first
            # available cruise
            @cruise = Cruise.find(:first)
        end

        expocode = @cruise.ExpoCode
        @file_result = _gather_file_result(
            expo_dirs[expocode], _expo_docs(expocode), expocode)
    end

    def all_cruise_meta
        get_cruise_meta()
        render :partial => "all_cruise_meta"
    end

end
