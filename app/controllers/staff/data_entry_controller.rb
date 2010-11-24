STAFF = {
  'danie' => 'Danie Kincade',
  'sdiggs' => 'Steve Diggs',
  'jkappa' => 'Jerry Kappa',
  'dave'   => 'Dave Muuse',
  'sarilee' => 'Sarilee Anderson',
  'jfields' => 'Justin Fields'
}
STATUS = {
  'Proposed' => '5',
  'On_Line' => '1',
  'Submitted' => '3',
  'Not_Measured' => '4',
  'No_Information' => '6',
  'Reformatted' => '2'
}
NUMSTATUS = {
  '5' => 'Proposed',
  '1' => 'On_Line',
  '3' => 'Submitted',
  '4' => 'Not_Measured',
  '6' => 'No_Information',
  '2' => 'Reformatted'
}

class Staff::DataEntryController < ApplicationController
  layout 'staff'
  before_filter :check_authentication
  auto_complete_for :cruise, :ExpoCode
  auto_complete_for :contact, :LastName

  def index
     @user = User.find(session[:user]).username
     @update_radio = " "
     @create_radio = "checked"
     #render :action => 'cruise_entry'
  end

############ CRUISE ENTRY ###########################################################
  def cruise_entry
     @update_radio = " "
     @create_radio = "checked"
     @parameter_codes = Code.all(:order => 'Code').map {|u| [u.Code, u.Status]}
     #render :partial => "cruise_entry"
     @cruises = Cruise.all(:order => 'Line')
     if params[:cruiseID]
       @cruise = Cruise.find(params[:cruiseID])
     end
     @collections = Collection.all(:order => 'Name')
  end
  
  def cruise_group_entry
     if params[:groupID]
       @collection = Collection.find(params[:groupID])
       @cruises = @collection.cruises
     else
       @cruises = Cruise.all
     end
     @collections = Collection.all(:order => 'Name')
     render 'cruise_entry'
  end
  
  def find_cruise
    @cruises = Cruise.all(:order => 'Line')
    if params[:ExpoCode]
      @cruise = Cruise.first(:conditions => [:ExpoCode => params[:ExpoCode]])
    elsif params[:cruiseID]
      @cruise = Cruise.find(params[:cruiseID])
    end
    @collections = Collection.all(:order => 'Name')
  end
  
  
  def put_cruise
    @db_result_message="Didn't put anything"
    if params[:cruise]
      @cruise = Cruise.new(params[:cruise])
      @cruise.save!
    else
      @db_result_message = "Couldn't save submission"
    end
    @cruises = Cruise.all(:order => 'Line')
    @collections = Collection.all(:order => 'Name')
    render :partial => 'cruise_entry'
  end
  
  
########## CRUISE ENTRY #############################################################


############# CRUISE GROUP ENTRY ###################################################
  def group_entry
     @groups = CruiseGroup.all
     render :partial => "group_entry"
  end
  
  # Updates the group_contents div
  def show_group
    if @group = params[:group] and @group =~ /\w/
      @cruise_group = CruiseGroup.first(:conditions => {:Group => @group})

      # Add the indicated cruise to the group
      if @expocode = params[:expocode]
        @cruise_group.Cruises = "#{@cruise_group.Cruises},#{@expocode}"
        @cruise_group.save!
      end
    end
    if @group or params[:cruise] and @group = params[:cruise][:Group] and @group =~ /\w/
      @cruises = @cruise_group.Cruises.split(',').map {|expocode| Cruise.first(:conditions => {:ExpoCode => expocode})}.compact
    end
    render :partial => "show_group"
  end
  
  def remove_group
    if params[:remove]
      @cruise_objects = []
  
      if @group = params[:group] || params[:cruise][:Group] and @group =~ /\w/
        @cruise_group = CruiseGroup.first(:conditions => {:Group => @group})
      end
      @cruises = @cruise_group.Cruises.split(',')
      @cruises.delete(params[:remove_expocode])
      @cruise_group.Cruises = @cruises.join(',')
      @cruise_group.save!  
      
      @cruise_objects = @cruises.map {|expocode| Cruise.first(:conditions => {:ExpoCode => expocode})}
    end
    render :partial => "show_group"  
  end
  
  def create_group
    if params[:cruise_group] and group = params[:cruise_group][:Group]
        @new_cruise_group = CruiseGroup.new
        @new_cruise_group.Group = group
        @new_cruise_group.Cruises = ""
        @new_cruise_group.Type = ""
        @new_cruise_group.save!
     # end
    end
    @groups = CruiseGroup.all
    render :partial => "group_entry"
  end
  
  def show_lines_for_group
    if line = params[:cruise][:Line]
      @lines = Cruise.all(:conditions => {:Line => line})
      if @group = params[:cruise][:Group] and @group =~ /\w/
        @cruise_group = CruiseGroup.first(:conditions => {:Group => @group})
        @cruises = @cruise_group.Cruises.split(',')
      end
    end
    @groups = CruiseGroup.all
    render :partial => "show_lines_for_group"
  end  
############# CRUISE GROUP ENTRY ###################################################



############# DATA HISTORIES #######################################################
  def event_entry
    if user = STAFF[User.find(session[:user]).username]
      (first, last) = user.split(' ')
    else
      first, last = 'Unknown', 'user'
    end
    @event = Event.new
    render :partial => "event_entry"
  end
  
  def create_event
    if params[:event]
      @event = Event.new(params[:event])
      #@event.Date_Entered = Time.now.strftime("%Y-%m-%d")
      @event.save
      if @expo = @event.ExpoCode
        @events = Event.all(:conditions => {:ExpoCode => @expo}, :order => 'Date_Entered DESC')
        @cruise = Cruise.first(:conditions => {:ExpoCode => @expo})
      end
      render :partial => "display_events"
    end
  end
  
  def display_events
    cur_sort = (['LastName', 'Data_Type'].include? params[:Sort]) ? params[:Sort] : 'Date_Entered DESC'
    if @expo = params[:ExpoCode]
      @events = Event.all(:conditions => {:ExpoCode => @expo}, :order => cur_sort)
      @cruise = Cruise.first(:conditions => {:ExpoCode => @expo})
    end
    if @note
      @note_entry = Event.first(:conditions => {:ID => @entry})
    end
    render :partial => "display_events"
  end
  
  def note
    @note_entry = Event.first(:conditions => {:ID => params[:Entry]})
    render :partial => "note"
  end
  
  def find_name
    if @last_name = params[:LastName]
      if @tmp_event = Contact.first(:conditions => {:LastName => @last_name})
        @first_name = @tmp_event.FirstName
        @event = Event.new
        @event.First_Name = @first_name
        @event.LastName = @last_name
      end
    end
    render :partial => "event_names"
  end
############# DATA HISTORIES #######################################################
  

############# CONTACTS  ############################################################
  def contact_entry
    if @contact_id = params[:contactID]
      @contact = Contact.first(:conditions => {:id => @contact_id})
    else
      @contact = Contact.new
    end
    @contacts = Contact.all(:order => 'LastName')
    #render :partial => "contact_entry"
  end
  
  def find_contact_entry
    # Auto complete the form if the last name can be found
    if params[:LastName]
      if @contact = Contact.first(:conditions => {:LastName => params[:LastName]})
       # @contacts = Contact.all#first(:conditions => {:LastName => params[:LastName]})
      else
        @contact = Contact.new
        @contact[:LastName] = params[:LastName]
      end
    end
    @contacts = Contact.all(:order => 'LastName')
    render :partial => "contact_entry"
  end
  
  def add_contact_cruise
    @contact = Contact.new
    @params_returned = params
    if params[:NewExpoCode] 
      if params[:contact][:id]
        if @contact = Contact.find(params[:contact][:id])
          if @cruise = Cruise.first(:conditions =>{:ExpoCode => params[:NewExpoCode]})
            @contact.cruises << @cruise
            #@contact_cruises_entry = ContactCruises.create :contact => @contact, :cruise => @cruise
          end
        end
      end
    end
    @contacts = Contact.all(:order => 'LastName')
    render :partial => "contact_entry"
  end
  
  def create_contact
    if params[:contact]
     # @contact = params[:contact]
      if params[:contact][:id] and params[:contact][:id] =~ /\d/
        @contact = Contact.find(params[:contact][:id])
        @contact.LastName = params[:contact][:LastName]
        @contact.FirstName = params[:contact][:FirstName]
        @contact.Institute = params[:contact][:Institute]
        @contact.Address = params[:contact][:Address]
        @contact.telephone = params[:contact][:telephone]
        @contact.fax = params[:contact][:fax]
        @contact.email = params[:contact][:email]
        @contact.title = params[:contact][:title]    
        @contact.save
      else
        @contact = Contact.new(params[:contact])
        @contact.save
      end
        
    end
    @contacts = Contact.all(:order => 'LastName')
    render :partial => "contact_entry"
  end  

#^^^^^^^^^^^^^^ CONTACTS  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

############### PARAMETERS #########################################################
  def parameter_entry
    @p_list = []
    @other_column_names = []
    @groups = ParameterGroup.find_by_sql("select distinct `group`,`parameters` from parameter_groups")
    for group in @groups
      g_list = group.parameters
      for g_param in (g_list.split(/,/))
         @p_list << g_param
      end
    end
    @column_names = Parameter.column_names
    @other_column_names = @column_names - @p_list
    if @expo = params[:ExpoCode] =~ /\w/
      @expo = nil unless @parameter = Parameter.first(:conditions => {:ExpoCode => @expo})
    end
    render :partial => "parameter_entry"
  end
  
  def submit_parameter
    @p_list = []
    @other_column_names = []
    @groups = ParameterGroup.find_by_sql("select distinct `group`,`parameters` from parameter_groups")
    for group in @groups
      g_list = group.parameters
      for g_param in (g_list.split(/,/))
         @p_list << g_param
      end
    end
    @column_names = Parameter.column_names
    for col in @column_names
      unless @p_list.include?(col)
        @other_column_names << col
      end
    end
    if params[:parameter]
       @par = Hash.new
       @par_temp = params[:parameter]
       @expo = @par_temp[:ExpoCode]
       for key in @par_temp.keys do
         if key =~ /NO3$/
           key = "NO2+NO3"
         elsif key =~/NO3_(.*)/
           key = "NO2+NO3_#{$1}"
         end
         @par[key] = @par_temp[key]
       end
       @parameter = Parameter.first(:conditions => {:ExpoCode => @expo}) || Parameter.new
       @parameter.attributes = @par
       @parameter.save!
     end
     render :partial => "parameter_entry"
  end
  
  

  
  def update_parameters
  end
  
#^^^^^^^^^^^^^^ PARAMETERS  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  
  
############### CRUISES #########################################################

  # create_cruise takes the information from the _cruise_entry.rhtml partial and processes it.
  #If the cruise entry is valid, it's created and saved.  If it's not valid, error messages are
  #passed back to the _cruise_entry.rhtml page.
  def being_removed_____create_cruise
    @parameter_codes = Code.find(:all,:order => "Code").map {|u| [u.Code, u.Status]}
    @param_list = []
    @message = ""
    @notice = "nothing"
    Parameter.find_by_sql("show columns from parameters").each do |p|
       if p.Field !~ /ExpoCode/ and p.Field !~ /id/ and p.Field !~ /_PI/ and p.Field !~ /_Date/i
          @param_list << p.Field
       end
    end
     @params = params
     saved = nil
     @form_parameters = Hash.new #This is a container that holds entered parameters when a cruise entry needs to be re-entered
     if params[:cruise]
       # UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE UPDATE #
       ############################################################################################################ 
        if params[:entry_type] =~ /Update/  # If we're editing an existing cruise
          if params[:cruise][:ExpoCode] =~ /\w/ and params[:cruise][:Line] !~ /\w/ # If we're pulling cruise info  
             # Prepare to edit an existing cruise
             @message = "Updating #{params[:cruise][:ExpoCode]}  #{params[:cruise][:Line]}"
             @update_radio = "checked"
             @create_radio = " "
             @cruise = Cruise.find(:first,:conditions => ["ExpoCode = '#{params[:cruise][:ExpoCode]}'"])
             parameters = nil
             parameters = Parameter.find(:first,:conditions => ["ExpoCode = '#{params[:cruise][:ExpoCode]}'"])
             for col in @param_list
               if parameters[:"#{col}"]
                 if parameters[:"#{col}_Date"]
                   year,month,day = parameters[:"#{col}_Date"].strftime("%Y-%m-%d").split("-")
                   @form_parameters["#{col}_year"] = year
                   @form_parameters["#{col}_month"] = month
                   @form_parameters["#{col}_day"] = day
                 else
                   @form_parameters["#{col}_year"] = ""
                   @form_parameters["#{col}_month"] = ""
                   @form_parameters["#{col}_day"] = ""
                 end
                 param_state = nil
                 param_state = parameters[:"#{col}"]
                 #param_state = param_state.to_i
                 #param_state = @parameter_codes[param_state]
                 @form_parameters["#{col}"] = NUMSTATUS[param_state] #@parameter_codes[parameters[:"#{col}"].to_i]
                 @form_parameters["#{col}_PI"] = parameters[:"#{col}_PI"]
               end # if parameters[:"#{col}"]
             end #for col in @param_list
          elsif params[:cruise][:ExpoCode] =~ /\w/ and params[:cruise][:Line] =~ /\w/
            # Check that the values have changed, then save changes
            @cruise = Cruise.find(:first,:conditions => ["ExpoCode = '#{params[:cruise][:ExpoCode]}'"])
            @new_parameter = Parameter.find(:first,:conditions => ["ExpoCode = '#{params[:cruise][:ExpoCode]}'"])
            @update_radio = "checked"
            @create_radio = " "
            #@new_parameter = Parameter.new
            for param in @params.keys do
               if @param_list.include?(param)
                  if params[:"#{param}_status"] =~ /\w/
                     @stat_test = params[:"#{param}_status"]
                     @stat = STATUS[@stat_test]
                     @new_parameter[:"#{param}"] = @stat
                     @new_parameter[:"#{param}_PI"] = params[:"#{param}"]
                     @form_parameters["#{param}"] = @stat_test
                     @form_parameters["#{param}_PI"] = params[:"#{param}"]
                     
                     if params[:"#{param}_year"] =~ /\d/ and params[:"#{param}_month"] =~ /\d/ and params[:"#{param}_day"] =~ /\d/
                       day = params[:"#{param}_day"]
                       month = params[:"#{param}_month"]
                       year = params[:"#{param}_year"]
                       @new_parameter[:"#{param}_Date"] = "#{year}-#{month}-#{day}"
                       @form_parameters["#{param}_year"] = year
                       @form_parameters["#{param}_month"] = month
                       @form_parameters["#{param}_day"] = day
                        if param =~ /CTD/i
                          @notice = "#{year}-#{month}-#{day}"
                        end
                       #@form_parameters["#{param}_Date"] = "#{year}-#{month}-#{day}"
                     end
                  end 
               end # if @param_list.include?(param)
            end # for param in @params.keys do  
            @message = "<b>#{params[:cruise][:ExpoCode]}</b> Updated<br><br>"
            @new_parameter.update
            parameters = nil
            parameters = Parameter.find(:first,:conditions => ["ExpoCode = '#{params[:cruise][:ExpoCode]}'"])
            for col in @param_list
              if parameters[:"#{col}"]
                if parameters[:"#{col}_Date"]
                  year,month,day = parameters[:"#{col}_Date"].strftime("%Y-%m-%d").split("-")
                  @form_parameters["#{col}_year"] = year
                  @form_parameters["#{col}_month"] = month
                  @form_parameters["#{col}_day"] = day
                else
                  @form_parameters["#{col}_year"] = ""
                  @form_parameters["#{col}_month"] = ""
                  @form_parameters["#{col}_day"] = ""
                end
                param_state = nil
                param_state = parameters[:"#{col}"]
                #param_state = param_state.to_i
                #param_state = @parameter_codes[param_state]
                @form_parameters["#{col}"] = NUMSTATUS[param_state] #@parameter_codes[parameters[:"#{col}"].to_i]
                @form_parameters["#{col}_PI"] = parameters[:"#{col}_PI"]
              end # if parameters[:"#{col}"]
            end #for col in @param_list
            
            
            
          end
         render :partial => "cruise_entry"
        # END UPDATE END UPDATE END UPDATE END UPDATE END UPDATE END UPDATE END UPDATE #
        ################################################################################
        
        # CREATE CREATE CREATE CREATE CREATE CREATE CREATE CREATE CREATE CREATE CREATE #
        ################################################################################
        elsif params[:entry_type] =~ /Create/ # if params[:entry_type] =~ /Update/
          if params[:cruise][:ExpoCode] =~ /\w/
            expo = params[:cruise][:ExpoCode]
            if @existing_cruise = Cruise.find(:first,:conditions => ["ExpoCode = '#{expo}'"])
              @message = "<B>Cruise Exists</B><br>Please Enter a unique ExpoCode<br>"
              @update_radio = " "
              @create_radio = "checked"
              render :partial => "cruise_entry"            
            else
              @cruise = Cruise.new(params[:cruise])  
              @update_radio = " "
               @create_radio = "checked"
              # Check that the new cruise object is valid
              if @new_parameter = Parameter.find(:first,:conditions => ["ExpoCode = '#{params[:cruise][:ExpoCode]}'"])
                
              else
                @new_parameter = Parameter.new
              end
              for param in @params.keys do
                 if @param_list.include?(param)
                    if params[:"#{param}_status"] =~ /\w/
                       @stat_test = params[:"#{param}_status"]
                       @stat = STATUS[@stat_test]
                       @new_parameter[:"#{param}"] = @stat
                       @new_parameter[:"#{param}_PI"] = params[:"#{param}_PI"]
                       @form_parameters["#{param}"] = @stat_test
                       @form_parameters["#{param}_PI"] = params[:"#{param}_PI"]
                       
                       if params[:"#{param}_year"] =~ /\d/ and params[:"#{param}_month"] =~ /\d/ and params[:"#{param}_day"] =~ /\d/
                         day = params[:"#{param}_day"]
                         month = params[:"#{param}_month"]
                         year = params[:"#{param}_year"]
                         @new_parameter[:"#{param}_Date"] = "#{year}-#{month}-#{day}"
                         @form_parameters["#{param}_year"] = year
                         @form_parameters["#{param}_month"] = month
                         @form_parameters["#{param}_day"] = day
                         #@form_parameters["#{param}_Date"] = "#{year}-#{month}-#{day}"
                       end
                    end 
                 end # if @param_list.include?(param)
              end # for param in @params.keys do
              
                begin
                   Cruise.transaction do
                      @cruise.Country.strip!
                      @cruise.ExpoCode.strip!
                      saved = @cruise.save!
                   end
                   rescue ActiveRecord::RecordInvalid => e
                      render :partial => "cruise_entry"
                end
              
              if saved
                 @new_parameter.ExpoCode = @cruise.ExpoCode
                 #@cruises = Cruise.find(:all,:conditions => ["ExpoCode = '#{@cruise.ExpoCode}' "])
                 @parameters = params
                 @new_parameter.save
                 @theta_status = params[:THETA_status]
                 @message = "#{@cruise.ExpoCode} row created in the cruises table"
                 render :partial => "cruise_entry"
              #else #if saved
              # render :partial => "cruise_entry"
              end
            end # if cruise already exists
          end
        end
      # END CREATE END CREATE END CREATE END CREATE END CREATE END CREATE END CREATE END CREATE END CREATE #
      ######################################################################################################
     else # if params[:cruise]
        render :partial => "cruise_entry"
     end
  end
#^^^^^^^^^^^^^^ CRUISES  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  

  
end
