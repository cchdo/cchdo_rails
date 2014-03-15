# Argo is a protected portion of the CCHDO site that serves as a drop box for
# proprietary files.

class ArgoController < ApplicationController
    before_filter :check_authentication, :except => [:signin]

    def index
        @files = Argo::File.find_all_by_display_and_content_type(true, 0) + Argo::File.find_all_by_display_and_content_type(true, 1) + Argo::File.find_all_by_display_and_content_type(true, 2)
        @files_admt14 = Argo::File.find_all_by_content_type(3)
        @files_ast14 = Argo::File.find_all_by_content_type(4)

        respond_to do |format|
          format.html # index.html.erb
          format.xml  { render :xml => @argo_files }
        end
    end

    def details
        unless @template.allowed_to_see_details()
            raise ActiveResource::UnauthorizedAccess
        else
            @files = Argo::File.all
            @hidden = Argo::File.count(:conditions => {:display => false})
        end
    end
end
