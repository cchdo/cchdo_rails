class FileSubmittedMailer < ActionMailer::Base
    default :from => "cchdo@ucsd.edu"

    def confirm(submission)
        identifiers = []
        identifiers << submission.Line if submission.Line =~ /\w/
        identifiers << submission.ExpoCode if submission.ExpoCode =~ /\w/

        @subject    =  "File submitted by #{submission.name}: #{identifiers.join(' ')}"
        @recipients = submission.email,'fieldsjustin@gmail.com','cchdo@ucsd.edu'
        @from       = ''
        @sent_on    = Time.now
        @headers    = {}
        @body['submission'] = submission
    end
end
