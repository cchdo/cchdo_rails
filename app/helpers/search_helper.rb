module SearchHelper
   def show_spinner
     content_tag "div",image_tag("rotate.gif"), :id => "busy", :style => "display:none;"
   end

    def sort_on(name, key=nil)
        if key.nil?
            key = name
        end
        if params['Sort'] == key and params['Sort_dir'] == 'ASC'
            dir = 'DESC'
        else
            dir = 'ASC'
        end
        link_to(name, params.merge(:Sort => key, :Sort_dir => dir))
    end
end
