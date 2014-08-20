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
 
    # GET /submit
    def new
      begin
        test = Priority.new()
        test.name = "test"
        test.save!
        test.destroy
        @read_only = false
      rescue
        @read_only = true
      end
    end

    # POST /submit
    def create
        SUBMITLOG.info("New Submission @ #{Time.now}")
        SUBMITLOG.info(params.inspect)
 
        # Create database record
        begin
            @submission = Submission.new(params[:submission])
            @submission.action = params[:actions]
            @submission.ip = request.env['REMOTE_ADDR']
            @submission.user_agent = request.user_agent()
        rescue Exception => msg
            SUBMITLOG.info("FAILED: Unable to create submission record: #{msg}")
            flash.now[:notice] = $MSGS[:sorry]
            render :action => :new, :status => 500
            return
        end
        if @submission.blank?
            SUBMITLOG.info("FAILED: No submission record created.")
            flash.now[:notice] = $MSGS[:sorry]
            render :action => :new, :status => 500
            return
        end
        @submission.action = params[:actions]

        SUBMITLOG.info("Saving record: #{@submission.inspect}")
 
        begin
            @submission.save!
        rescue ActiveRecord::RecordInvalid => msg
            @submission.unsave_file()
            SUBMITLOG.info("FAILED: invalid record: #{msg}")
            SUBMITLOG.info(@submission.errors)
            flash.now[:notice] = $MSGS[:incomplete]
            render :action => :new, :status => 400
            return
        rescue Exception => msg
            @submission.unsave_file()
            SUBMITLOG.info("FAILED: ERROR: #{msg}\n\n#{msg.backtrace}")
            flash.now[:notice] = $MSGS[:sorry]
            render :action => :new, :status => 500
            return
        end

        if ENV['RAILS_ENV'] == 'production'
            begin
                raise "Blank submission" unless @submission
                FileSubmittedMailer.deliver_confirm(@submission)
                SUBMITLOG.info('Confirmed')
            rescue Exception => msg
                SUBMITLOG.warn("Unable to send confirmation email: #{msg}")
            end
        end

        SUBMITLOG.info("DONE.")
    end
end
