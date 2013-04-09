module DataAccessHelper
    def self_or_empty(x)
        x ? x : ''
    end

    def display_subcategory(header_level, section, files)
        header = section.title
        types = section.types

        mapped = []
        for ftype in section.types
            file = files[ftype.key_name]
            if not file or file == 0
                next
            end
            mapped << [ftype, file]
        end
        
        if mapped.empty?
            return ''
        end

        result = content_tag(header_level, header)
        result += content_tag(:ul, :class => "formats") do
            ulresult = ''
            for ftype, file in mapped
                ulresult += content_tag(:li) do
                    liresult = content_tag(:span, 
                        link_to(
                            ftype.short_name, file,
                            :expocode => @cruise.ExpoCode,
                            :file_type => ftype.key_name),
                        :class => "file_type") + \
                        content_tag(:abbr, '?', :title => ftype.description) + \
                    ''
                    #content_tag(:span, :class => "bulk") do
                    #    if @bulk.include?([@cruise.id, file])
                    #        link_to('Add to downloads', :controller => 'bulk', :action => 'add', :cruise_id => @cruise.id, :file => file)
                    #    else
                    #        "In bulk download #{link_to('Remove', :controller => 'bulk', :action => 'remove', :cruise_id => @cruise.id, :file => file)}"
                    #    end
                    #end
                    #liresult
                end
            end
            ulresult
        end
        result
    end

    def show_files(format_sections, files)
        result = ''
        for section in format_sections
            if section.has_subsections?
                result += content_tag(:h2, section.title)
                result += content_tag(:ul, :class => "sub-formats") do
                    ulresult = ''
                    for subsection in section.subsections
                        ulresult += content_tag(
                            :li, display_subcategory(:h3, subsection, files))
                    end
                    ulresult
                end
            else
                result += display_subcategory(:h2, section, files)
            end
        end
        result
    end
end
