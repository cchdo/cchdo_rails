class Minute < ActiveRecord::Base
    has_many :action_items
end

class ActionItem < ActiveRecord::Base
    belongs_to :minute
end

require 'models/document'
require 'models/event'
require 'models/submission'

class StaffController < ApplicationController
    layout "staff", :except => [:pis_for_lookup, :ships_for_lookup,
                                :countries_for_lookup, :parameters_for_lookup,
                                :expocodes_for_lookup, :contacts_for_lookup,
                                :lines_for_lookup]
    before_filter :check_authentication, :except => [:signin, :images, :pis_for_lookup,
                                       :ships_for_lookup,
                                       :countries_for_lookup,:parameters_for_lookup,
                                       :expocodes_for_lookup,
                                       :contacts_for_lookup, :lines_for_lookup]
#cache_sweeper :task_tracker

def index
    @user = User.find(session[:user])
    @user = @user.username
    params[:query] = @user
end

# Static pages
def software
    #render :partial => "software"
end

def documentation 
    #render :partial => "documentation"
end


# Minutes Code------------------------------------------------------------------

def minutes_archive
    @minutes = Minute.find(:all,:order => "Date DESC")
end

def enter_minutes
    @minute = Minute.new
    15.times { @minute.action_items.build }
    render :partial => 'enter_minutes'
end

def create_minutes
    if params[:minutes]
        @minutes = Minute.new(params[:minutes])
        params[:action_items].each_value do |action_item|
            @minutes.action_items.build(action_item) unless action_item.values.all?(&:blank?)
        end
    end
    @minutes.save 
    @minutes = Minute.all(:order => "Date DESC")
    render :partial => "minutes"
end

def update_action_items
    action_item = ActionItem.find(params[:item_id])
    action_item.done = params[:done]
    action_item.save

    @minutes = Minute.all(:order => "Date DESC")
    render :partial => "minutes"
end


####################################################
##### Submitted Files ##############################

def _queue_submissions
    queue_submissions = Hash.new {|h, k| h[k] = []}
    for qf in QueueFile.all()
        if qf.submission_id != 0
            queue_submissions[qf.submission_id] << qf
        end
    end
    queue_submissions
end

$submission_sort_columns = [
    "submission_date", "name", "institute", "Country", "email", "Line",
    "ExpoCode", "Ship_Name", "cruise_date"
]

def _submission_list_type(condition_name, pre_conditions=nil)
    if params[:sort] and $submission_sort_columns.include?(params[:sort])
        sort_condition = params[:sort]
    else
        sort_condition = params[:sort] = 'submission_date'
    end
    if sort_condition == 'submission_date'
        sort_condition += ' DESC'
    end

    if condition_name == 'all'
        type_cond = nil
    elsif condition_name == 'argo'
        type_cond = "public = 'argo'"
    elsif condition_name == 'unassigned'
        type_cond = "assigned = 0"
    elsif condition_name == 'not_queued'
        type_cond = "assimilated = 0"
    elsif condition_name == 'not_queued_not_argo'
        type_cond = "assimilated = 0 AND (public IS NULL OR public != 'argo')"
    else
        type_cond = "assimilated = 0 AND (public IS NULL OR public != 'argo')"
    end
    unless pre_conditions.nil?
        conditions = [[pre_conditions[0], type_cond].map {|x| "(#{x})"}.join(' AND ')]
        conditions.concat([pre_conditions.slice(1..-1)])
    else
        conditions = [type_cond].compact
    end
    Rails.logger.debug(conditions.inspect)
    Rails.logger.debug(sort_condition.inspect)
    @submissions = Submission.find(
        :all, :conditions => conditions, :order => sort_condition)
end

def submitted_files
    user = User.find(session[:user])
    if not user or user.username =~ /guest/
        raise ActionController::RoutingError.new('Unauthorized')
    end

    list_type = params[:submission_list]
    if not list_type
        list_type = params[:submission_list] = 'not_queued_not_argo'
    end
    _generate_submission_list(list_type)
    render :file => "/staff/submitted_files/submitted_files", :layout => true
end

def _best_submission_query_condition(query)
    cur_max = -1
    best_condition = nil
    for column in Submission.columns
        condition = ["`#{column.name}` regexp ?", query]
        results = Submission.count(:conditions => condition)
        if results > cur_max
            cur_max = results
            best_condition = condition
        end
    end
    return best_condition
end

def _generate_submission_list(list_type)
    if list_type == 'old_submissions'
        @old_submissions = OldSubmission.all()
    else
        @query = params[:query] || ''
        if @query.length > 0
            query_conditions = _best_submission_query_condition(@query)
        else
            query_conditions = nil
        end
        Rails.logger.debug(query_conditions)

        _submission_list_type(list_type, query_conditions)
        @queue_submissions = _queue_submissions()
    end
end

def enqueue
    return_uri = '/staff/submitted_files'
    expocode = params['enqueue_attach_to_expocode']
    submission_id = params['enqueue_submission']

    user = User.find(session[:user])

    sub_link = "<a href=\"#sub_#{submission_id}\">#{submission_id}</a>"
    couldnot = "Could not enqueue #{sub_link}: "

    cruise = reduce_specifics(Cruise.find_by_ExpoCode(expocode))
    if cruise.nil?
        flash[:notice] = "#{couldnot}Could not find cruise #{expocode} to attach to"
        redirect_to return_uri
        return
    end
    submission = Submission.find(submission_id)
    if submission.nil?
        flash[:notice] = "#{couldnot}Could not find submission"
        redirect_to return_uri
        return
    end
    opts = {
        'notes' => params['enqueue_notes'],
        'parameters' => params['enqueue_parameters'],
        'documentation' => params['enqueue_documentation'] == 'on'
    }
    if opts['notes'].nil?
        flash[:notice] = "#{couldnot}Missing notes"
        redirect_to return_uri
        return
    end
    if opts['parameters'].nil?
        flash[:notice] = "#{couldnot}Missing data type"
        redirect_to return_uri
        return
    end
    if opts['documentation'].nil?
        flash[:notice] = "#{couldnot}Missing documentation flag"
        redirect_to return_uri
        return
    end

    dont_email = params['enqueue_noemail'] || false

    begin
        event = QueueFile.enqueue(user, submission, cruise, opts)
        if ENV['RAILS_ENV'] == 'production' and not dont_email
            EnqueuedMailer.deliver_confirm(event)
        else
            Rails.logger.debug(event.inspect)
        end
        flash[:notice] = "Enqueued Submission #{sub_link}"
        redirect_to return_uri
    rescue => e
        Rails.logger.warn(e)
        flash[:notice] = "#{couldnot}#{e}"
        redirect_to return_uri
    end
end

def show_note
    @note_id = params[:sub_id]
    @submission_note = Submission.find(@note_id)
    @submission_note[:notes].gsub!(/[\n]/,"<br>")
    @submission_note[:notes].gsub!(/[\t]/,"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")
    render :partial => "/staff/submitted_files/show_note"
end

def hide_note
    @note_id = params[:sub_id]
    @submission = Submission.find(@note_id)
    render :partial => "/staff/submitted_files/hide_note"
end

#########################################################################
# Code for smart forms

def pis_for_lookup
	@pis = Cruise.find(:all, :select => ["DISTINCT Chief_Scientist"])
	response.headers['Content-Type'] = 'text/javascript'
	
	# make things easier for the browser
	str = "var pis = ["
	@pis.each do |pi|
		str += "\"#{pi.Chief_Scientist}\","
	end
	str = str[0..-2] + "];"
	render :text => "#{str}"
end

def contacts_for_lookup
	@contacts = Contact.find(:all, :select => ["DISTINCT LastName"])
	response.headers['Content-Type'] = 'text/javascript'
	
	# make things easier for the browser
	str = "var contacts = ["
	@contacts.each do |contact|
		str += "\"#{contact.LastName}\","
	end
	str = str[0..-2] + "];"
	render :text => "#{str}"
end

def expocodes_for_lookup
	@expocodes = Cruise.find(:all, :select => ["DISTINCT ExpoCode"])
	response.headers['Content-Type'] = 'text/javascript'
	
	# make things easier for the browser
	str = "var expocodes = ["
	@expocodes.each do |expocode|
		str += "\"#{expocode.ExpoCode}\","
	end
	str = str[0..-2] + "];"
	render :text => "#{str}"
end

def ships_for_lookup
	@ships = Cruise.find(:all, :select => ["DISTINCT Ship_Name"])
	response.headers['Content-Type'] = 'text/javascript'
	
	# make things easier for the browser
	str = "var ships = ["
	@ships.each do |ship|
		str += "\"#{ship.Ship_Name}\","
	end
	str = str[0..-2] + "];"
	render :text => "#{str}"
end

def countries_for_lookup
	@countries = Cruise.find(:all, :select => ["DISTINCT Country"])
	response.headers['Content-Type'] = 'text/javascript'
	
	# make things easier for the browser
	str = "var countries = ["
	@countries.each do |country|
		str += "\"#{country.Country}\","
	end
	str = str[0..-2] + "];"
	render :text => "#{str}"
end


def parameters_for_lookup
	@parameters = Parameter.column_names.delete_if {|x| x =~ /ExpoCode/ or x =~ /id/ or x =~ /_PI/ or x =~ /Date/i}

	response.headers['Content-Type'] = 'text/javascript'
	
	# make things easier for the browser
	str = "var parameters = ["
	@parameters.each do |parameter|
		str += "\"#{parameter}\","
	end
	str = str[0..-2] + "];"
	render :text => "#{str}"
end

def lines_for_lookup
    @lines = Cruise.find(:all, :select => ["DISTINCT Line"])
    response.headers['Content-Type'] = 'text/javascript'

    # make things easier for the browser
    str = "var lines = ["
    @lines.each do |line|
        str += "\"#{line.Line}\","
    end
    str = str[0..-2] + "];"
    render :text => "#{str}"
end
#--------------------Db-History----------------------------------
def db_history
    @documents = Document.find_by_sql("select * from cchdo.documents where DATE_SUB(CURDATE(),interval 2 month) <= LastModified order by LastModified DESC")  #find documents that are most recently changed 
    @events = Event.find_by_sql("select * from cchdo.events where DATE_SUB(CURDATE(),interval 2 month) <= Date_Entered order by Date_Entered DESC") #find events that have the most recent date on the notes
    @submissions = Submission.find_by_sql("select * from cchdo.submissions where DATE_SUB(CURDATE(),interval 2 month) <= submission_date order by submission_date DESC")  #find documents that are most recently changed 
end

def StaffController.doc_from(date, documents)
    doc_array = Array.new
    documents.each do |document| 
        if document.LastModified.strftime(fmt='%Y-%m-%d') == date.to_s
            doc_array << document
        end
    end
    return doc_array
end

def StaffController.event_from(date, events, expocode)
    event_array = Array.new
    if expocode == "NULL"
        return event_array
    end
    events.each do |event|
        if event.Date_Entered.to_s == date.to_s and event.ExpoCode == expocode
            event_array << event
        end
    end
    return event_array
end

def StaffController.no_doc_event_from(date, events, used_expocodes)
    event_array = Array.new
    events.each do |event|
        if event.Date_Entered.to_s == date.to_s and !used_expocodes.include?(event.ExpoCode)
            event_array << event
        end
    end
    return event_array
end

def StaffController.submission_from(date, submissions)
    submission_array = Array.new
    submissions.each do |submission|
        if submission.submission_date.to_s == date.to_s 
            submission_array << submission
        end
    end
    return submission_array
end
end
