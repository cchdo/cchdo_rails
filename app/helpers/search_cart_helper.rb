module SearchCartHelper
  def show_spinner
    content_tag "div",image_tag("rotate.gif"), 
                :id => "busy", :style => "display:none;"
  end
end
