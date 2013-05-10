module CruiseStatusHelper
    def link_file(file_result, link_text)
        output = ''
        if file_result
            output = link_to(link_text, file_result.FileName)
            begin
                unless File.stat(file_result.FileName).readable?
                    output += content_tag(:span, 'File is not readable by public', :class => 'permissions')
                end
            rescue => err
                output += content_tag(:span, err.to_s, :class => 'error')
            end
            if file_result.respond_to?(:Stamp)
                output += content_tag(:span, file_result.Stamp, :class => 'stamp')
            end
            output = content_tag(:li, output)
        end
        return output
    end
end
