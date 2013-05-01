class GroupsController < ApplicationController
    def index
        redirect_to search_path(:query => "group:#{params[:id]}")
        return
    end
end
