class SearchController < ApplicationController
   def index
     find_by_params_query()
   end
end
