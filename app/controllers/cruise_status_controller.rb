class CruiseStatusController < ApplicationController
    layout "staff"

    before_filter :check_authentication

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

    $file_short_types = $type_to_long_type.keys() + ['big_pic', 'small_pic']

    $allowed_event_sorts = ['LastName', 'Data_Type']

    def index
        cruise_information()
        render :action => 'cruise_information'
    end

    def cruise_information
        cruises = Cruise.find(:all)
        @cruises = _organize_cruises(cruises)
        (@no_files_cruises, @some_files_cruises, file_results) = _flag_cruises(cruises)
        _get_cruise_meta()
    end

    def all_cruise_meta
        _get_cruise_meta()
        render :partial => "all_cruise_meta"
    end

    def note
        @entry = params[:Entry]
        @note_entry = Event.find_by_ID(@entry)
        render :partial => "note"
    end

    def sheet
        cruises = Cruise.find(:all)
        (_0, _1, file_results) = _flag_cruises(cruises)

        response = ''
        for cruise in cruises
            cruise_responses = []
            cruise_responses << cruise.ExpoCode

            fr = file_results[cruise.ExpoCode]
            for key in $file_short_types
                doc = fr[key]
                if doc
                    if doc.respond_to?('FileType')
                        cruise_responses << doc.FileType
                    else
                        cruise_responses << doc
                    end
                end
            end

            response += cruise_responses.join(',') + "\n"
        end

        render :text => response
    end

    def _expo_dirs(expocode=nil)
        if expocode
            docs = Document.find_all_by_FileType_and_ExpoCode(
                'Directory', expocode)
        else
            docs = Document.find_all_by_FileType('Directory')
        end
        expo_dirs = docs.reduce({}) {|h, dir| h[dir.ExpoCode] = dir; h }
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

    def _count_missing(file_result)
        num_files = 0
        for type in $file_short_types
            if file_result[type]
                num_files += 1
            end
        end
        return num_files
    end

    def _flag_cruises(cruises)
        @cruise_list = cruises
        file_results = {}
        missing_all_cruises = []
        missing_some_cruises = []

        expo_dirs = _expo_dirs()
        expo_docs = _expo_docs()
        for cruise in cruises
            expocode = cruise.ExpoCode
            file_results[expocode] = _gather_file_result(
                expo_dirs, expo_docs, expocode)

            num_files = _count_missing(file_results[expocode])
            if num_files == 0
                missing_all_cruises << cruise.ExpoCode
            elsif num_files < 11
                missing_some_cruises << cruise.ExpoCode
            end
        end
        return missing_all_cruises, missing_some_cruises, file_results
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

    def _gather_file_result(doc_dirs, expo_docs, expocode)
        file_result = {}
        $file_short_types.each {|k| file_result[k] = nil}
        file_result['big_pic'] = nil
        file_result['small_pic'] = nil

        doc_dir = doc_dirs[expocode]
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

    def _get_cruise_meta()
        expocode = params[:expo]
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
            _expo_dirs(expocode), _expo_docs(expocode), expocode)
    end
end
