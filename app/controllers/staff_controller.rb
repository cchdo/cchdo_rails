class Minute < ActiveRecord::Base
    has_many :action_items
end

class ActionItem < ActiveRecord::Base
    belongs_to :minute
end

require 'csv'

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

#-------------------------------------------------------------------------
# queue files

def queue_files
    @user = User.find(session[:user]).username

    @documentation = 0
    if params[:docs]
        @documentation = 1
    end

    merge_status = 0
    # 0 - not merged

    # group by date of first unmerged file for cruise
    #   group by cruise

    files = QueueFile.find_all_by_Merged_and_documentation(
        merge_status, @documentation, :order => :DateRecieved)

    files_by_cruise = Hash.new {|h, k| h[k] = []}
    for file in files
        files_by_cruise[file.ExpoCode] << file
    end

    cruises_by_earliest_unmerged_date = Hash.new {|h, k| h[k] = []}
    for cruise in files_by_cruise.keys()
        files = files_by_cruise[cruise]
        date = nil
        for file in files
            if date.nil?
                date = file.DateRecieved
                next
            end
            if file.DateRecieved < date
                date = file.DateRecieved
            end
        end
        cruises_by_earliest_unmerged_date[date] << cruise
    end

    @files_by_cruise = files_by_cruise
    @cruises_by_earliest_unmerged_date = cruises_by_earliest_unmerged_date

    eudates = @cruises_by_earliest_unmerged_date.keys().reject {|x| x.nil?}
    eudates.sort!
    eudates.reverse!
    @eudates = eudates
    render :file => "/staff/queue_files/queue_files", :layout => true
end

def queue_edit
    @user = User.find(session[:user]).username

    queue = QueueFile.find(params[:id])
    unless queue
        flash[:notice] = "That is not a valid queue file"
        redirect_to "/queue" && return
    end

    if params[:commit] == 'Save note'
        queue.merge_notes = params[:merge_notes]
        queue.save
        flash[:notice] = "Saved note for queue file #{queue.id}"
    elsif params[:commit] == 'Mark merged'
        queue.DateMerged = Time.now
        queue.Merged = 1
        queue.save
        flash[:notice] = "Marked queue file #{queue.id} as merged"
    end
    redirect_to "/queue"
end

def queue_search
    @best_result = []
    @cur_max = 0
    @names = []
    @cruises = []
    @results = []
    if  @query = params[:queue_file][:query] 
        for column in QueueFile.columns
            @names << column.human_name
            @results = QueueFile.find(:all ,:conditions => ["`#{column.name}` regexp ?", @query], :order => "Merged")
            if @results.length > @cur_max
                @cur_max = @results.length
                @best_result = @results
                @results=[]
            end
        end
    end
    @files = @best_result
    for file in @files
        cruise = Cruise.find(:first,:conditions => ["ExpoCode = ?",file.ExpoCode])
        if cruise
            @cruises << cruise
        end
    end  
    @cruises.uniq!
    render :partial => "/staff/queue_files/queue_box"
end

def show_all
    @files = QueueFile.find(:all,:order => "Merged")
    @cruises = Array.new
    for file in @files
        cruise = Cruise.find(:first,:conditions => ["ExpoCode = ?",file.ExpoCode])
        if cruise
            @cruises << cruise
        end
    end
    @cruises.uniq!
    render :partial => '/staff/queue_files/queue_box'
end

def cruise_queue
    expo = params[:cruise]
    @columns = ["Name", "Contact", "Original","DateRecieved", "Merged"]
    @cruise = Cruise.find(:first, :conditions => ["ExpoCode = ?",expo])
    @queue = QueueFile.find(:all, :conditions => ["ExpoCode = ?",expo],:order => "Merged")
    @events = Event.find(:all,:conditions=>["ExpoCode= ?",expo],:order=>['Date_Entered DESC'])
    render :partial => '/staff/queue_files/cruise_queue'
end

def note
    @entry = params[:Entry]
    @note_entry = Event.find(:first,:conditions=>["ID=#{@entry}"])
    render :partial => "/staff/queue_files/note"
end


####################################################
##### Submitted Files ##############################

def submitted_files
    @user = User.find(session[:user])
    @user = @user.username
    @submissions = Submission.find(:all, :order => "submission_date DESC")
    @queue_submissions = Hash.new {|h, k| h[k] = []}
    for qf in QueueFile.all()
        if qf.submission_id != 0
            @queue_submissions[qf.submission_id] << qf
        end
    end
    render :file => "/staff/submitted_files/submitted_files", :layout => true
end

def submission_list
    condition = params[:submission_list]
    @parameters = params
    if params[:Sort]
        sort_condition = params[:Sort]
    else
        sort_condition = "submission_date"
    end
    if condition == 'all'
        @submissions = Submission.find(:all,:order => sort_condition)
    elsif condition == 'unassigned'
        @submissions = Submission.find(:all, :conditions => ["assigned = '0'"], :order => sort_condition)
    elsif condition == 'unassimilated'
        @submissions = Submission.find(:all, :conditions => ["assimilated = '0'"], :order => sort_condition)
    end
    render :partial => "/staff/submitted_files/submission_list"
end

def enqueue
    return_uri = '/staff/submitted_files'
    expocode = params['enqueue_attach_to_expocode']
    submission_id = params['enqueue_submission']

    user = User.find(session[:user])

    sub_link = "<a href=\"#sub_#{submission_id}\">#{submission_id}</a>"
    couldnot = "Could not enqueue #{sub_link}: "

    cruise = Cruise.find_by_ExpoCode(expocode)
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

    begin
        event = QueueFile.enqueue(user, submission, cruise, opts)
        EnqueuedMailer.deliver_confirm(event)
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

def submission_search
    @best_result = []
    @cur_max = 0
    @names = []
    @submissions = []
    @results = []
    if @query = params[:submission][:query] 
        for column in Submission.columns
            @names << column.human_name
            @results = Submission.find(
                :all,
                :conditions => ["`#{column.name}` regexp ?", @query],
                :order => "submission_date DESC")
                if @results.length > @cur_max
                    @cur_max = @results.length
                    @best_result = @results
                    @results=[]
                end
        end
    end
    @submissions = @best_result
    render :partial => "/staff/submitted_files/submission_list"
end

def old_submissions
    @old_submissions = OldSubmission.find(:all)
    @cruisesTEST = Cruise.find(:all)
    render :partial => "/staff/submitted_files/old_submission_list"
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
