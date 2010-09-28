module ArgoHelper
    ALLOWED_TO_SEE_DETAILS = %w[sdiggs myshen jfields ayshen cberys]

    def allowed_to_see_details
        if session[:user] and user = User.find(session[:user])
            ALLOWED_TO_SEE_DETAILS.include?(user.username)
        else
            false
        end
    end
end
