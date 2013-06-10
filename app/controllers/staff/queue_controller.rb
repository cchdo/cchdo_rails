class Staff::QueueController < ApplicationController
    layout 'staff'
    before_filter :check_authentication, :except => [:signin]

    def queue_files
        # Providing any of parameters id, expocode will only show the queue for
        # that file or cruise's files

        @user = User.find(session[:user]).username

        @documentation = 0
        if params[:docs]
            @documentation = 1
        end

        # 0 - not merged
        # 1 - merged
        # 2 - hidden
        if merge_status = params[:merge_status]
            if merge_status == 'hidden'
                merge_status = 2
            elsif merge_status == 'merged'
                merge_status = 1
            else
                merge_status = 0
            end
        else
            merge_status = 0
        end

        # group by date of first unmerged file for cruise
        #   group by cruise

        if params[:id]
            files = QueueFile.find_all_by_id(params[:id])
        elsif params[:expocode]
            files = QueueFile.find_all_by_ExpoCode(params[:expocode])
        else
            files = QueueFile.find_all_by_Merged_and_documentation(
                merge_status, @documentation, :order => :DateRecieved)
        end

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
        respond_to do |format|
          format.html {
            render :file => "/staff/queue_files/queue_files", :layout => true
          }
          format.csv {
            csv_string = FasterCSV.generate do |csv| 
              csv << [
                'date', 'woce_line', 'expocode', 'filepath', 'contact',
                'date_received', 'submission_id', 'parameters', 'notes',
                'merge_notes'] 
              cruises = reduce_specifics(Cruise.find_all_by_ExpoCode(@files_by_cruise.keys()))
              cruises_by_expo = Hash.new {|h, k| h[k] = []}
              for cruise in cruises
                cruises_by_expo[cruise.ExpoCode] << cruise
              end
              for date in @eudates
                for expo in @cruises_by_earliest_unmerged_date[date]
                  for file in @files_by_cruise[expo]
                    if file.submission_id != 0
                      begin
                        cruise = cruises_by_expo[expo][0]
                        line = cruise.Line
                      rescue
                        line = nil
                      end
                      csv << [
                        date, line, expo, file.UnprocessedInput, file.Contact,
                        file.DateRecieved, file.submission_id, file.Parameters,
                        file.Notes, file.merge_notes
                      ]
                    end
                  end
                end
              end
            end 
            if @documentation
              data_docs = 'unmerged_docs'
            else
              data_docs = 'unmerged_data'
            end
            send_data csv_string, 
              :type => 'text/csv; charset=utf-8; header=present', 
              :disposition => "inline; filename=queue_#{data_docs}_#{DateTime.now.strftime('%FT%T')}.csv" 
          }
        end
    end

    def queue_edit
        @user = User.find(session[:user]).username

        queue = QueueFile.find(params[:id])
        unless queue
            flash[:notice] = "That is not a valid queue file"
            return redirect_to("/queue")
        end

        queue_link = "<a href=\"queue?id=#{queue.id}\">#{queue.id}</a>"
        if params[:commit] == 'Save parameters'
            queue.Parameters = params[:parameters]
            queue.save
            flash[:notice] = "Saved parameters for queue file #{queue_link}"
        elsif params[:commit] == 'Save submission note'
            queue.Notes = params[:submission_notes]
            queue.save
            flash[:notice] = "Saved note for queue file #{queue_link}"
        elsif params[:commit] == 'Save merge note'
            queue.merge_notes = params[:merge_notes]
            queue.save
            flash[:notice] = "Saved note for queue file #{queue_link}"
        elsif params[:commit] == 'Mark unmerged'
            queue.DateMerged = Time.now
            queue.Merged = 0
            queue.save
            flash[:notice] = "Marked queue file #{queue_link} as unmerged"
        elsif params[:commit] == 'Mark merged'
            queue.DateMerged = Time.now
            queue.Merged = 1
            queue.save
            flash[:notice] = "Marked queue file #{queue_link} as merged"
            return redirect_to("/queue?merge_status=merged")
        elsif params[:commit] == 'Mark documentation'
            queue.documentation = 1
            queue.save
            flash[:notice] = "Marked queue file #{queue_link} as documentation"
        elsif params[:commit] == 'Mark not documentation'
            queue.documentation = 0
            queue.save
            flash[:notice] = "Marked queue file #{queue_link} as not documentation"
        elsif params[:commit] == 'Unhide'
            queue.DateMerged = Time.now
            queue.Merged = 0
            queue.save
            flash[:notice] = "Unhid queue file #{queue_link}"
        elsif params[:commit] == 'Hide'
            queue.DateMerged = Time.now
            queue.Merged = 2
            queue.save
            flash[:notice] = "Hid queue file #{queue_link}"
            return redirect_to("/queue?merge_status=hidden")
        end
        redirect_to :back
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
            cruise = reduce_specifics(Cruise.find(:first,:conditions => ["ExpoCode = ?",file.ExpoCode]))
            if cruise
                @cruises << cruise
            end
        end  
        @cruises.uniq!
        render :partial => "/staff/queue_files/queue_box"
    end
end
