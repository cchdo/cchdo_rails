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
end

class String
  def smart_pluralize(num=self)
    num.to_i.abs == 1 ? self : pluralize
  end
end
