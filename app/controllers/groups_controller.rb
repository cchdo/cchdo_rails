class GroupsController < ApplicationController
  def index
    if params[:id]
      @group = params[:id]
    elsif params[:query]
      @group = params[:query]
      #params[:expanded] = 'true'
    else
      @group = 'Atlantic Onetime'
    end
    @query_with_sort_link = "groups?id=#{@group}"
    @sort_statement = ""
    @sort_check = ["Line","ExpoCode","Begin_Date","Ship_Name","Chief_Scientist","Country"]
    if @sort_by = params[:Sort] and @sort_check.include?(@sort_by)
      @sort_statement = @sort_by
      #@query_with_sort_link << "&Sort=#{@sort_by}"
    end
    @query_link  = @query_with_sort_link
    @table_list = Hash.new{|@table_list,k| @table_list[k]={}}
    @param_list = Hash.new{|h,k| h[k]={}}
    @codes = Code.all.inject({}) {|hash, code| hash[code.Code] = code.Status }

    # Get all cruises from group
    if @sort_statement and @sort_statement =~ /\w/
      @cruises = Cruise.all(:conditions => "`Group` REGEXP '#{@group}'", :order => "#{@sort_statement}")
    else
      @cruises = Cruise.all(:conditions => "`Group` REGEXP '#{@group}'")
    end

    for cruise in @cruises
      if cruise.ExpoCode =~ /\w/
        @table_list[cruise.ExpoCode]['woce_sum'] = ''
        # Collect Bottle, CTD, Document file info
        if cruise.Country =~ /\w/ 
          if COUNTRIES.values.include?(cruise.Country.downcase.strip)
            cruise.Country = (COUNTRIES.invert[cruise.Country.downcase] || '').capitalize
            if cruise.Country =~ /\s/
              cruise.Country = cruise.Country.split.map {|e| e.capitalize}.join(' ')
            end
            if cruise.Country =~ /^usa?$/i
              cruise.Country = 'USA'
            end
          end
        end
        @files_for_expocode = cruise.get_files() 
        @files_for_expocode["Preliminary"] = ''
        if Document.count(:conditions => {:ExpoCode => cruise.ExpoCode, :Preliminary => 1}) > 0
          @files_for_expocode["Preliminary"] = "Preliminary (See <a href=\"http://cchdo.ucsd.edu/data_history?ExpoCode=#{cruise.ExpoCode}\">data history</a>)"
        end
        @table_list[cruise.ExpoCode] = @files_for_expocode

        @param_list[cruise.ExpoCode]['stations'] = 0
        @param_list[cruise.ExpoCode]['parameters'] = ""
        if cruise_parameters = BottleDB.first(:conditions => {:ExpoCode => cruise.ExpoCode})
          @param_list[cruise.ExpoCode]['stations'] = cruise_parameters.Stations
          if cruise_parameters.Parameters =~ /\w/
            param_list = cruise_parameters.Parameters
            @param_list[cruise.ExpoCode]['parameters'] = param_list
            param_array = param_list.split(',')
            persistance_array = cruise_parameters.Parameter_Persistance.split(',')
              
            param_array.zip(persistance_array).each do |param, persistance|
              @param_list[cruise.ExpoCode][param] = persistance
            end
          end
        end
      end # if cruise.ExpoCode
    end # for cruise in @cruises      
    render :template => '/search/index'
  end
end
