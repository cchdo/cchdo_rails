if @updates.blank?
    atom_feed do |f|
        f.title("No CCHDO updates for #{params[:expocodes]}")
        f.updated(DateTime.now())
    end
else
    atom_feed do |f|
        f.title("CCHDO Updates for #{@header}")
        f.updated(@updates.first.feed_datetime())
    
        for update in @updates
            next if update.feed_datetime().blank?
            f.entry(update, {:url => cruise_path(update.ExpoCode)}) do |entry|
                info = update.feed_info()
                entry.title(info[:title])
                entry.content(info[:content], :type => :html)
                entry.updated(update.feed_datetime().strftime("%Y-%m-%dT%H:%M:%SZ"))
                entry.author do |author|
                    author.name(info[:author])
                end
            end
        end
    
    end
end
