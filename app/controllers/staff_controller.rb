class Minutes < ActiveRecord::Base
end

require 'csv'
class StaffController < ApplicationController
layout "staff", :except => [:pis_for_lookup, :ships_for_lookup, :countries_for_lookup, :parameters_for_lookup, :expocodes_for_lookup, :contacts_for_lookup, :lines_for_lookup]
before_filter :check_authentication, :except => [:signin, :images, :pis_for_lookup, :ships_for_lookup, :countries_for_lookup,:parameters_for_lookup, :expocodes_for_lookup, :contacts_for_lookup, :lines_for_lookup]
#cache_sweeper :task_tracker

def index
   @user = User.find(session[:user])
   @user = @user.username
   params[:query] = @user
end

# Static pages
def software
  render :partial => "software"
end

def documentation 
  render :partial => "documentation"
end


# Minutes Code------------------------------------------------------------------

def minutes_archive
   @minutes = Minutes.find(:all,:order => "Date DESC")
end

def enter_minutes
  render :partial => 'enter_minutes'
end

def create_minutes
  if params[:minutes]
     @minutes = Minutes.new(params[:minutes])
     @minutes.save
   end
   @minutes = Minutes.find(:all,:order => "Date DESC")
   render :partial => "minutes"
end

def update_action_items
 if clicked = params[:clicked_action_item]     
   find = String.new(clicked)
   if clicked =~ /[':"()$*]/
       find = find.gsub(/'/, "\\\\\'")
       find = find.gsub(/:/, "\\\\\:")
       find = find.gsub(/"/, "\\\\\"")
       find = find.gsub(/[(]/, "\\\\\(")
       find = find.gsub(/[)]/, "\\\\\)")
       find = find.gsub(/[$]/, "\\\\\$")
       find = find.gsub(/[*]/, "\\\\\*")
       find = find.gsub(/[.]/, "\\\\\.")
   end
     
    if things = Minutes.find_by_sql("SELECT * FROM `minutes` WHERE action_items LIKE '%#{find}%' ORDER BY id DESC LIMIT 1") and not things.empty?
      minutes = things.first
      star = clicked + "(*)"
      minutes.action_items = minutes.action_items.gsub(/#{clicked}/, "#{star}")

      # items = minutes.action_items.split(',')
      # items[items.index(clicked)] += '(*)'
      # minutes.action_items = items.join(',')

      
      unless minutes.save
        # Big error
      end
   end
 end   

   @minutes = Minutes.find(:all,:order => "Date DESC")
   render :partial => "minutes"
end

def undo_action_items
 if clicked = params[:clicked_action_item]     
   find = String.new(clicked)
   if clicked =~ /\(\*\)/
     find = find.gsub(/\(\*\)/, "")
    if clicked =~ /[':"()$*]/
        find = find.gsub(/'/, "\\\\\'")
        find = find.gsub(/:/, "\\\\\:")
        find = find.gsub(/"/, "\\\\\"")
        find = find.gsub(/[(]/, "\\\\\(")
        find = find.gsub(/[)]/, "\\\\\)")
        find = find.gsub(/[$]/, "\\\\\$")
        find = find.gsub(/[*]/, "\\\\\*")
        find = find.gsub(/[.]/, "\\\\\.")
    end
  end
     
    if things = Minutes.find_by_sql("SELECT * FROM `minutes` WHERE action_items LIKE '%#{find}%' ORDER BY id DESC LIMIT 1") and not things.empty?
      minutes = things.first
      unstar = clicked.gsub(/\(\*\)/, "")
      clicked = clicked.gsub(/\(\*\)/, "\\\\\(\\\\\*\\\\\)").strip
      minutes.action_items = minutes.action_items.gsub(/#{clicked}/, "#{unstar}")

      # items = minutes.action_items.split(',')
      # items[items.index(clicked)] += '(*)'
      # minutes.action_items = items.join(',')

      
      unless minutes.save
        # Big error
      end
   end
 end   

   @minutes = Minutes.find(:all,:order => "Date DESC")
   render :partial => "minutes"
end

#-------------------------------------------------------------------------
# queue files

def queue_files
    @user = User.find(session[:user])
  @user = @user.username
   @files = QueueFile.find(:all,:order => "Merged")
       @cruises = Array.new
  for file in @files
    cruise = Cruise.find(:first,:conditions => ["ExpoCode = ?",file.ExpoCode])
    if cruise
      @cruises << cruise
    end
  end
  @cruises.uniq!
  render :file => "/staff/queue_files/queue_files", :layout => true
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
      @results = QueueFile.find(:all ,:conditions => ["`#{column.name}` regexp '#{@query}'"],:order => "Merged")
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
   @submissions = Submission.find(:all,:order => "submission_date DESC")
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
      @submissions = Submission.find(:all,:order => "#{sort_condition}")
   elsif condition == 'unassigned'
      @submissions = Submission.find(:all, :conditions => ["assigned = '0'"],:order => "#{sort_condition}")
   elsif condition == 'unassimilated'
      @submissions = Submission.find(:all, :conditions => ["assimilated = '0'"],:order => "#{sort_condition}")
   end
   render :partial => "/staff/submitted_files/submission_list"
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
  if  @query = params[:submission][:query] 
    for column in Submission.columns
        @names << column.human_name
        @results = Submission.find(:all ,:conditions => ["`#{column.name}` regexp '#{@query}'"])
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
	@pis = Cruise.find(:all,
			:select => ["DISTINCT Chief_Scientist"])
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
	@contacts = Contact.find(:all,
			:select => ["DISTINCT LastName"])
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
	@expocodes = Cruise.find(:all,
			:select => ["DISTINCT ExpoCode"])
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
	@ships = Cruise.find(:all,
			:select => ["DISTINCT Ship_Name"])
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
	@countries = Cruise.find(:all,
			:select => ["DISTINCT Country"])
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

end
