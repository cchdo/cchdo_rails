module CruiseStatusHelper
    def link_file(file_result, link_text)
        output = ''
        if file_result
            output = link_to(link_text, file_result.FileName)
            if file_result.respond_to?(:Stamp)
                output += content_tag(:span, file_result.Stamp)
            end
            output = content_tag(:li, output)
        end
        return output
    end
end
