module DocumentsHelper
    include DatacartHelper

    def display_subcategory(dir, expocode, header_level, section, files, short)
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

        ul_class = "formats"
        if short
            result = ''
            ul_class += " short"
        else
            result = content_tag(header_level, header)
        end

        ulresult = ''
        for ftype, file in mapped
            short_name = ftype.short_name
            if short
                short_name = "#{header} #{short_name}"
            end

            basename = File.basename(file)
            link_file = datacart_link_file(dir, basename, expocode)

            liresult = content_tag(:span, 
                link_to(
                    short_name, file,
                    :expocode => expocode,
                    :file_type => ftype.key_name),
                :class => "file_type") + \
            content_tag(:abbr, '?', :title => ftype.description) + \
            content_tag(:span, link_file, :class => "datacart")
            ulresult += content_tag(:li, liresult)
        end
        result += content_tag(:ul, ulresult, :class => ul_class)
        result
    end

    def show_files(cruise, files, short=false)
        directory = cruise.directory
        expocode = cruise.ExpoCode
        result = ''

        result += datacart_link_cruise(cruise)
        sec_result = ''

        for section in Document.data_format_sections
            if section.has_subsections?
                ulresult = ''
                for subsection in section.subsections
                    liresult = display_subcategory(directory, expocode, :h3, subsection, files, short)
                    unless liresult.empty?
                        ulresult += content_tag(:li, liresult)
                    end
                end
                unless ulresult.empty?
                    ul_class = "sub-formats"
                    unless short
                        sec_result += content_tag(:h2, section.title)
                    else
                        ul_class += " short"
                    end
                    sec_result += content_tag(:ul, ulresult, :class => ul_class)
                end
            else
                sec_result += display_subcategory(directory, expocode, :h2, section, files, short)
            end
        end
        result + content_tag(:div, sec_result, :class => 'formats-sections')
    end
end
