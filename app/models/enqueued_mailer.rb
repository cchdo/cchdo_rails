class EnqueuedMailer < ActionMailer::Base
    def confirm(event)
        if event.Data_Type.length == 0
            event.Data_Type = nil
        end
        subject ["Enqueued #{event.ExpoCode} data", event.Data_Type].reject {|x| x.nil?}.join(' - ')
        from 'cchdo@ucsd.edu'
        if Rails.env.production?
            recipients ['cchdo@googlegroups.com']
        else
            recipients ['myshen+test@ucsd.edu']
        end
        sent_on Time.now()
        body :event => event
    end
end
