module ArgoHelper
    ALLOWED_TO_SEE_DETAILS = %w[sdiggs myshen jfields ayshen cberys]

    def allowed_to_see_details
        ALLOWED_TO_SEE_DETAILS.include?(User.find(session[:user]).username)
    end
end
