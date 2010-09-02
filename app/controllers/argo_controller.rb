# Argo is a protected portion of the CCHDO site that serves as a drop box for
# proprietary files.

class ArgoController < ApplicationController
    before_filter :check_authentication, :except => [:signin]

    def index
        @files = Argo::File.all(:conditions => {:display => true})

        respond_to do |format|
          format.html # index.html.erb
          format.xml  { render :xml => @argo_files }
        end
    end
end
