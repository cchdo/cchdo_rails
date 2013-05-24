class LegacyController < ApplicationController
    def data_access_advanced_search
        redirect_to search_advanced_path
    end

    def search
        redirect_to search_path(:query => "group:#{params[:id]}")
    end

    def data_history
        unless params[:ExpoCode]
            redirect_to search_advanced_path
        else
            redirect_to cruise_path(
                :expocode => params[:ExpoCode], :anchor => 'history')
        end
    end
end
