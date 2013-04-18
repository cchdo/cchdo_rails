# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def sortable_heading( label, field, make_link, update_div )
    up_params = { :order => field, :direction => 'asc' }
    down_params = { :order => field, :direction => 'desc' }
    "#{label} %s %s" % [
      link_to_remote( '[up]',:update => update_div, :url => make_link.call( up_params ) ),
      link_to_remote( '[down]',:update => update_div, :url => make_link.call( down_params ) )
    ]
  end

  def link_file_if_exists(link, linktext, description, needslinebreak=Nil)
    if link != 0
      linebreak = needslinebreak ? '<br />' : ''
      "#{linebreak}#{link_to linktext, link} - #{description}"
    end
  end

  def getGAPIkey(host)
    return case host
      #when 'cchdo.ucsd.edu':        'ABQIAAAAZICfw-7ifUWoyrSbSFaNixTec8MiBufSHvQnWG6NDHYU8J6t-xTRqsJkl7OBlM2_ox3MeNhe_0-jXA'
      when 'cchdo.ucsd.edu':        'ABQIAAAATXJifusyeTqIXK5-oRfMqRTec8MiBufSHvQnWG6NDHYU8J6t-xQu6FK5KGtXjapXKCGo-If8o-ibsQ'
      #when 'whpo.ucsd.edu':         'ABQIAAAATXJifusyeTqIXK5-oRfMqRRrtQtAbE2ICKyeJmE150l9FUtvWRQ_qb0gC6W0P4gBV_W3RstdZXEcOw'
      #when 'watershed.ucsd.edu':    'ABQIAAAATXJifusyeTqIXK5-oRfMqRRkZzjLi0nUJ4TwOC8xt4Ov2IJhKBQTGSNz9nt4_eT3w1Wv_O1VSaMyBA'
      #when 'goship.ucsd.edu:3000':  'ABQIAAAATXJifusyeTqIXK5-oRfMqRSVxuI6xAiiU0y37vRLQcURlSg9FhSh-0iK98GAcbE_yabEYgs-ehj6Xg'
      #when 'goship.ucsd.edu:3001':  'ABQIAAAATXJifusyeTqIXK5-oRfMqRSr8-l44IzDbkbBv97f-HWDFg7I8BRpdaDASGE34kKJc5YWLpfZBx47WA'
      #when 'goship.ucsd.edu:3002':  'ABQIAAAATXJifusyeTqIXK5-oRfMqRRB1RN-V0XmX5z1VbT-eeaOdUc4_hT1v2Zx5xPptz95mPR00pZfDsnm0A'
      #when 'ghdc.ucsd.edu:3000':    'ABQIAAAATXJifusyeTqIXK5-oRfMqRQbm_T9Aut8KIkQepcdoibG6hz3ZBSwpsEu6JXesbZc0gcOonL9xKdIBA'
    else
      #'ABQIAAAAnfs7bKE82qgb3Zc2YyS-oBT2yXp_ZAY8_ufC3CFXhHIE1NvwkxSySz_REpPq-4WZA27OwgbtyR3VcA'
    end
  end

    # Pretty print dates for cruises while being mindful of security regulations
    def format_date(date, format, default=nil)
        if date
            begin
                date.strftime(format)
            rescue
                default
            end
        else
            default
        end
    end

    def reduced?(cruise)
        if cruise.Begin_Date
            if cruise.EndDate
                if (    cruise.Begin_Date.mon == 1 and
                        cruise.Begin_Date.day == 1 and 
                        cruise.EndDate.mon == 1 and
                        cruise.EndDate.day == 1)
                    return true
                end
            else
                if cruise.Begin_Date.mon == 1 and cruise.Begin_Date.day == 1
                    return true
                end
            end
        else
            if cruise.EndDate and cruise.EndDate.mon == 1 and cruise.EndDate.day == 1
                return true
            end
        end
        return false
    end

    def pretty_dates(cruise, format="%a %b %e, %Y", joinstr=' <b>-</b>')
        if reduced?(cruise)
            format = "%Y"
        end
        dates = [
            format_date(cruise.Begin_Date, format),
            format_date(cruise.EndDate, format)
        ]
        return dates.compact.join(joinstr)
    end

    def limit_str_len(s, limit, trailer='...')
        if s.length > limit
            return s.slice(0..limit - trailer.length) + trailer
        end
        return s
    end

    def datacart_link(act, link={}, html={})
        link_to(content_tag(:div, act, :class => "datacart-icon"), link, html)
    end

    def datacart_link_file(act, dir, basename)
        if act == 'Remove'
            action = 'remove'
            classname = 'datacart-remove'
            title = 'Remove from data cart'
        elsif act == 'Add'
            action = 'add'
            classname = 'datacart-add'
            title = 'Add to data cart'
        end

        datacart_link(act,
            {
                :controller => 'datacart',
                :action => action,
                :dirid => dir.id,
                :file => basename
            }, {
                :class => classname,
                :title => title
            })
    end

    def datacart_link_cruise(act, cruise)
        if act == 'Remove'
            action = 'remove_cruise'
            classname = 'datacart-remove datacart-remove-cruise'
            title = 'Remove all cruise data from data cart'
        elsif act == 'Add'
            action = 'add_cruise'
            classname = 'datacart-add datacart-add-cruise'
            title = 'Add all cruise data to data cart'
        end

        datacart_link("#{act} all",
            {
                :controller => 'datacart',
                :action => action,
                :cruise_id => cruise.id
            }, {
                :class => classname,
                :title => title
            })
    end

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
        result += content_tag(:ul, :class => ul_class) do
            ulresult = ''
            for ftype, file in mapped
                ulresult += content_tag(:li) do
                    short_name = ftype.short_name
                    if short
                        short_name = "#{header} #{short_name}"
                    end
                    liresult = content_tag(:span, 
                        link_to(
                            short_name, file,
                            :expocode => expocode,
                            :file_type => ftype.key_name),
                        :class => "file_type") + \
                    content_tag(:abbr, '?', :title => ftype.description) + \
                    content_tag(:span, :class => "datacart") do
                        basename = File.basename(file)
                        if @datacart.include?([dir.id, basename])
                            datacart_link_file('Remove', dir, basename)
                        else
                            datacart_link_file('Add', dir, basename)
                        end
                    end
                    liresult
                end
            end
            ulresult
        end
        result
    end

    def show_files(cruise, format_sections, files, short=false)
        directory = cruise.directory
        expocode = cruise.ExpoCode
        result = ''

        result += content_tag(:div, datacart_link_cruise('Add', cruise) + datacart_link_cruise('Remove', cruise), :class => "datacart-cruise")

        for section in format_sections
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
                        result += content_tag(:h2, section.title)
                    else
                        ul_class += " short"
                    end
                    result += content_tag(:ul, ulresult, :class => ul_class)
                end
            else
                result += display_subcategory(directory, expocode, :h2, section, files, short)
            end
        end
        result
    end
end

class String
  def smart_pluralize(num=self)
    num.to_i.abs == 1 ? self : pluralize
  end
end
