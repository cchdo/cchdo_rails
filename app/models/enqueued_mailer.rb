class EnqueuedMailer < ActionMailer::Base
    def confirm(event)
        if event.Data_Type.length == 0
            event.Data_Type = nil
        end
        subject_str = ["Enqueued #{event.ExpoCode} data", event.Data_Type].reject {|x| x.nil?}.join(' - ')
        if Rails.env.production?
            recipients ['cchdo@googlegroups.com']
        else
            subject_str = 'TEST ' + subject_str
            recipients ['myshen+test@ucsd.edu']
        end
        subject subject_str
        from 'cchdo@ucsd.edu'
        sent_on Time.now()
        body :event => event
    end
end
