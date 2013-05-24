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
    layout "staff"
    before_filter :check_authentication, :except => [:signin, :images]
    #cache_sweeper :task_tracker

def index
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
