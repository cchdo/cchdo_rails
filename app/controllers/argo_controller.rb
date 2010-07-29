class ArgoSubmission < ActiveRecord::Base
end

class ArgoController < ApplicationController
before_filter :check_authentication, :except => [:signin]

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
     @files = ArgoSubmission.find(:all )
     for file in @files
       @user = User.find(file.user)
        file.user = @user.username
      end
  end
  
  def save_file
     $save_dir = "/Library/WebServer/Documents/cchdo/public/argo_submissions"
     if(params[:file])
        saved = nil
        @file = params[:file]
       if not @file.class.to_s.eql?("String") #=~ /\w/
        @file_name = @file.original_filename
        @file_name.gsub(/[^\w\.\-]/,'_')
        @file_submission = ArgoSubmission.new(params[:argo_submission])
        @file_submission.user = session[:user] 
        @file_submission.filename = @file_name
        @file_submission.location = "argo_submissions/#{@file_name}"
        @file_submission.datetime_added = DateTime.now()
        @file_submission.save
         file_type = @file.content_type
         File.open("#{$save_dir}/#{@file_name}", "wb") do |f|
            f.write(params[:file].read)
         end #File.open(..) do |f|
       end # if  not @file.class.to_s.eql?("String")
     end # if(params[:file])
     @files = ArgoSubmission.find(:all )
     redirect_to "http://cchdo.ucsd.edu/argo"
  end
  
  def delete
    @user = User.find(session[:user])
    @files = ArgoSubmission.find(:all, :conditions => [" user = '#{session[:user]}'"] )
     for file in @files
       @user = User.find(file.user)
        file.user = @user.username
      end
  end
  
  def delete_file
    @file = params[:File]
    location = ArgoSubmission.find(@file)
    
    loc = location.location
    ArgoSubmission.delete(location)
    `rm /Library/WebServer/Documents/cchdo/public/#{loc}`
    redirect_to "http://cchdo.ucsd.edu/argo"
  end
  
  
end
