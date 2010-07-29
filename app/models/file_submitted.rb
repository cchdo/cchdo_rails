class FileSubmitted < ActionMailer::Base

  def confirm(submission)
    @file_identifier = String.new
    if submission.Line =~ /\w/
       @file_identifier << "#{submission.Line} "
    end
    if submission.ExpoCode =~ /\w/
       @file_identifier << "#{submission.ExpoCode}"
    end
    @subject    =  "File submitted by #{submission.name}  #{@file_identifier}"
    @body['submission']       = submission
    @recipients = submission.email,'fieldsjustin@gmail.com','cchdo@ucsd.edu'
    @from       = ''
    @sent_on    = Time.now
    @headers    = {}
  end
end
