module SubmitHelper
  def step_header(number, header)
    content_tag(:tr, escape=false) do
      content_tag(:td, escape=false) do
        content_tag(:span, {:class => :step2}, escape=false) do
          'Step' + content_tag(:span, number, :class => :step_number2) + ':'
        end + ' ' + 
        content_tag(:span, header, :class => :step_title)
      end
    end
  end
end
