class Staff::SubmissionsController < StaffController
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
        elsif condition_name == 'id'
            type_cond = "id = #{(params[:query] || '0').to_i}"
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
            conditions = [[pre_conditions[0], type_cond].compact.map {|x| "(#{x})"}.join(' AND ')]
            conditions.concat([pre_conditions.slice(1..-1)])
        else
            conditions = [type_cond].compact
        end
        @submissions = Submission.find(
            :all, :conditions => conditions, :order => sort_condition)
    end

    def index
        user = User.find(session[:user])
        if not user or user.username =~ /guest/
            raise ActionController::RoutingError.new('Unauthorized')
        end

        list_type = params[:submission_list]
        if not list_type
            list_type = params[:submission_list] = 'not_queued_not_argo'
        end
        _generate_submission_list(list_type)
        render :file => "/staff/submissions/index", :layout => true
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
            if @query.length > 0 and list_type != 'id'
                query_conditions = _best_submission_query_condition(@query)
            else
                query_conditions = nil
            end

            _submission_list_type(list_type, query_conditions)
            @queue_submissions = _queue_submissions()
        end
    end

    def enqueue
        expocode = params['enqueue_attach_to_expocode']
        submission_id = params['enqueue_submission']

        user = User.find(session[:user])

        sub_link = "<a href=\"query=#{submission_id}&submission_list=id\">#{submission_id}</a>"
        couldnot = "Could not enqueue #{sub_link}: "

        cruise = reduce_specifics(Cruise.find_by_ExpoCode(expocode))
        if cruise.nil?
            flash[:notice] = "#{couldnot}Could not find cruise #{expocode} to attach to"
            redirect_to :back
            return
        end
        submission = Submission.find(submission_id)
        if submission.nil?
            flash[:notice] = "#{couldnot}Could not find submission"
            redirect_to :back
            return
        end
        opts = {
            'notes' => params['enqueue_notes'],
            'parameters' => params['enqueue_parameters'],
            'documentation' => params['enqueue_documentation'] == 'on'
        }
        if opts['notes'].nil?
            flash[:notice] = "#{couldnot}Missing notes"
            redirect_to :back
            return
        end
        if opts['parameters'].nil?
            flash[:notice] = "#{couldnot}Missing data type"
            redirect_to :back
            return
        end
        if opts['documentation'].nil?
            flash[:notice] = "#{couldnot}Missing documentation flag"
            redirect_to :back
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
            redirect_to submissions_path(
                :query => submission_id, :submission_list => 'id')
        rescue => e
            Rails.logger.warn(e)
            flash[:notice] = "#{couldnot}#{e}"
            redirect_to :back
        end
    end
end
