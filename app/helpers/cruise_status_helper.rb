module CruiseStatusHelper
    def link_file(file_result, link_text)
        output = ''
        if file_result
            output = link_to(link_text, file_result.FileName)
            unless File.stat(file_result.FileName).readable?
                output += content_tag(:span, 'File is not readable by public', :class => 'permissions')
            end
            if file_result.respond_to?(:Stamp)
                output += content_tag(:span, file_result.Stamp, :class => 'stamp')
            end
            output = content_tag(:li, output)
        end
        return output
    end
end
