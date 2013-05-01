class LegacyController < ApplicationController
    def search
        redirect_to search_path(:query => "group:#{params[:id]}")
        return
    end
end
