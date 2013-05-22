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

    def year_month_selector(month_name, year_name, year_start=1980)
        month_options = []
        for month in 1..12
            month_options << [month.to_s, month.to_s]
        end
        year_options = []
        for year in (year_start..Date.today.year).to_a.reverse
            year_options << [year.to_s, year.to_s]
        end
        select_tag(month_name, options_for_select(month_options)) + \
        select_tag(year_name, options_for_select(year_options))
    end
end
