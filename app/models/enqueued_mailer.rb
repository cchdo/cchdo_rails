class EnqueuedMailer < ActionMailer::Base
    def confirm(event)
        subject ["[CCHDO] Enqueued #{event.ExpoCode} data", event.Data_Type].join(' - ')
        from 'cchdo@ucsd.edu'
        recipients ['jkappa@ucsd.edu']
        cc ['cchdo@googlegroups.com']
        sent_on Time.now()
        body :event => event
    end
end
