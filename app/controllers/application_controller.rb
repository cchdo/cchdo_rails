require 'cruise_data_formats'

COUNTRIES = {
   'germany'     => 'ger', 'japan' => 'jpn',
   'france'      => 'fra', 'england' => 'uk',
   'canada'      => 'can', 'us' => 'usa',
   'usa'         => 'usa', 'india' => 'ind',
   'russia'      => 'rus', 'spain' => 'spn',
   'argentina'   => 'arg', 'ukrain' => 'ukr',
   'netherlands' => 'net', 'norway' => 'nor',
   'finland'     => 'fin', 'iceland' => 'ice',
   'australia'   => 'aus', 'chile' => 'chi',
   'new zealand' => 'new', 'taiwan' => 'tai',
   'china'       => 'prc'
}

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class Array
  def oob_to_nil
    oob_value = -999
    oob_tolerance = 1
    return self.map do |x|
      if oob_value-oob_tolerance <= x and x <= oob_value+oob_tolerance
        nil
      else
        x
      end
    end
  end
end

class ApplicationController < ActionController::Base
    layout 'standard'

    before_filter :setup_datacart

    # Scrub sensitive parameters from your log
    filter_parameter_logging :password, :password_confirmation

    protect_from_forgery

    unless ActionController::Base.consider_all_requests_local
        rescue_from Exception, :with => :render_500
        rescue_from ActiveResource::UnauthorizedAccess, :with => :render_401
        rescue_from ActiveRecord::RecordNotFound,
                    ActionController::RoutingError,
                    ActionController::UnknownController,
                    ActionController::UnknownAction,
                    ActionController::MethodNotAllowed do |exception|
             render_404(exception)
        end
    end

    def render_401(exception)
        @code = 401
        @message = "Unauthorized"
        render 'errors/errors', :status => :unauthorized
    end

    def render_404(exception)
        Rails.logger.error("404 for #{exception.inspect}")
        @code = 404
        @message = "Not found"
        render 'errors/errors', :status => :not_found
    end

    def render_500(exception)
        Rails.logger.error("500 for #{exception.inspect}")
        Rails.logger.error(exception.backtrace.slice(0..10).join("\n"))
        Rails.logger.error('traceback snipped')
        @code = 500
        @message = "Oops! That is an error. We are looking into it."
        render 'errors/errors', :status => :internal_server_error
    end

    def signin
        if request.post?
            if user = User.authenticate(params[:username], params[:password])
                session[:user] = user.id
                session[:username] = params[:username]
                intended_path = session[:intended_path] || '/'
                redirect_to intended_path
            else
                flash[:notice] = "Invalid user name or password"
            end
        else
            session[:intended_path] = request.referrer || '/'
        end
    end

    def signout
        session[:user] = nil
        session[:username] = nil
        redirect_to :back
    rescue ActionController::RedirectBackError
        redirect_to signin_path
    end

    def needs_reduction(cruise, date)
        return false unless cruise

        return false if session[:user]

        if (    (cruise.ExpoCode and cruise.ExpoCode =~ /^3[1-3]/) and 
                ((cruise.Begin_Date and cruise.Begin_Date > date) or
                 (cruise.EndDate and cruise.EndDate > date)))
            return true
        end
        return false
    end

    def reduce_specifics(cruises)
        # Comply with federal security regulations and remove specifics about
        # USA ships in the future
        # specifics include ports of call and departure/arrival dates
        # It is allowed to specify year, however.
        if cruises.nil?
            return cruises
        end
        today = Date.today
        was_singular = false
        if cruises.kind_of?(Cruise) or cruises.kind_of?(CarinaCruise)
             was_singular = true
             cruises = [cruises]
        end
        cruises.each do |cruise|
            if needs_reduction(cruise, today)
                Rails.logger.info(
                    "Reducing specifics for cruise #{cruise.ExpoCode}")
                if cruise.Begin_Date
                    cruise.Begin_Date = Date.new(cruise.Begin_Date.year)
                end
                if cruise.EndDate
                    cruise.EndDate = Date.new(cruise.EndDate.year)
                end
            end
        end
        if was_singular
            return cruises[0]
        end
        return cruises
    end

protected

    def setup_datacart
        begin
            @datacart = session['datacart'] || Datacart.new()
        rescue ActionController::SessionRestoreError
            session.clear()
        end
    end

    def check_authentication
        unless session[:user]
            session[:intended_path] = request.path
            redirect_to signin_path
        else
            user = User.find(session[:user])
            if user.username =~ /guest/
                redirect_to :controller => :staff
            end
        end
    end

    # Provide the message used to indicate a cruise is preliminary
    def preliminary_message(cruise)
        expo = cruise.ExpoCode
        any_preliminary = Document.exists?(:ExpoCode => expo, :Preliminary => 1)
        if any_preliminary
            "Preliminary (See <a href=\"/cruise/#{expo}#history\">data history</a>)"
        else
            ""
        end
    end

    def load_files_and_params(cruise)
        files_for_expocode = cruise.get_files()
        files_for_expocode["Preliminary"] = preliminary_message(cruise)

        param_for_expocode = {
            'stations' => 0,
            'parameters' => {},
        }
        params = param_for_expocode['parameters']
        cruise_parameters = BottleDB.find_by_ExpoCode(cruise.ExpoCode)
        if cruise_parameters
            param_for_expocode['stations'] = (cruise_parameters.Stations || 0).to_i
            param_list = cruise_parameters.Parameters
            param_persistance = cruise_parameters.Parameter_Persistance
            if param_list =~ /\w/ and param_persistance =~ /\w/
                param_array = param_list.split(',')
                persistance_array = param_persistance.split(',')
                for param, persist in param_array.zip(persistance_array)
                    next if param !~ /\w/
                    next if param =~ /castno|flag|time|expocode|sampno|sect_id|depth|latitude|longitude|stnnbr|btlnbr|date|stations|parameters/i
                    params[param] = persist.to_i
                end
            end
        end
        [files_for_expocode, param_for_expocode]
    end
end
