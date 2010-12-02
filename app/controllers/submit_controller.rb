class SubmitController < ApplicationController
    layout 'standard'
 
    upload_status_for :save_file
    
    $PLEASE_EMAIL = "Please email your submission to " + 
                    "<a href=\"mailto:cberysgo@ucsd.edu\">" + 
                    "cberysgo@ucsd.edu</a>."
    $MSGS = {
        :sorry => "<p>Sorry! We're having problems right now. " + 
                  "#{$PLEASE_EMAIL}</p>",
        :incomplete => "<p>Please correct the " + 
                       "errors in the form and resubmit.</p>",
    }
 
    # GET /submit/simple
    def simple
    end

    # GET /submit
    def new
    end

    # POST /submit
    def create
        SUBMITLOG.info("New Submission @ #{Time.now}")
        SUBMITLOG.info(params.inspect)
 
        # Create database record
        @submission = Submission.new(params[:submission])
        @submission.action = params[:actions]

        SUBMITLOG.info("Saving record: #{@submission.inspect}")
 
        begin
            @submission.save!
        rescue ActiveRecord::RecordInvalid => msg
            @submission.unsave_file()
            SUBMITLOG.info("FAILED: invalid record: #{msg}")
            flash.now[:notice] = $MSGS[:incomplete]
            render :action => :new, :status => 400
            return
        rescue Exception => msg
            @submission.unsave_file()
            SUBMITLOG.info("FAILED: ERROR: #{msg}")
            flash.now[:notice] = $MSGS[:sorry]
            render :action => :new, :status => 500
            return
        end

        if ENV['RAILS_ENV'] == 'production'
            begin
                FileSubmittedMailer.confirm(@submission).deliver
            rescue Exception => msg
                SUBMITLOG.warn("Unable to send confirmation email: #{msg}")
            end
        end

        SUBMITLOG.info("DONE.")
    end
end
