# Argo is a protected portion of the CCHDO site that serves as a drop box for
# proprietary files.

class ArgoController < ApplicationController
    before_filter :check_authentication, :except => [:signin]

    def index
        @files = Argo::File.find_all_by_display(true)

        respond_to do |format|
          format.html # index.html.erb
          format.xml  { render :xml => @argo_files }
        end
    end

    def details
        unless @template.allowed_to_see_details()
            render :file => 'public/401.html', :status => :unauthorized
        else
            @files = Argo::File.all
            @hidden = Argo::File.count(:conditions => {:display => false})
        end
    end
end
