class FileSubmittedMailer < ActionMailer::Base

    def confirm(submission)
        identifiers = []
        identifiers << submission.Line if submission.Line =~ /\w/
        identifiers << submission.ExpoCode if submission.ExpoCode =~ /\w/

        subject "File submitted by #{submission.name}: #{identifiers.join(' ')}"
        recipients [submission.email, 'fieldsjustin@gmail.com', 'cchdo@ucsd.edu'].uniq
        from 'cchdo@ucsd.edu'
        sent_on Time.now()
        body :submission => submission
    end
end
