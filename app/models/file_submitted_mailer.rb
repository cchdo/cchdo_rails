class FileSubmittedMailer < ActionMailer::Base
    helper :submit

    def confirm(submission)
        identifiers = []
        identifiers << submission.Line if submission.Line =~ /\w/
        identifiers << submission.ExpoCode if submission.ExpoCode =~ /\w/

        subject "[CCHDO] Submission by #{submission.name}: #{identifiers.join(' ')}"
        from 'cchdo@ucsd.edu'
        recipients [submission.email].uniq
        cc ['cchdo@ucsd.edu']
        sent_on Time.now()
        body :submission => submission
    end
end
