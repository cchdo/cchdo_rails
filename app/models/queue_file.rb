require 'zip/zip'

require 'submission'

class QueueFile < ActiveRecord::Base
    set_table_name "queue_files"

    belongs_to :submission

    def self.enqueue(user, submission, cruise, opts={})
        Rails.logger.info("enqueueing #{submission.inspect} #{cruise.inspect}")
        begin
            data_dir = cruise.data_dir()
        rescue
            raise 'No data directory'
        end
        if not File.directory?(data_dir)
            Rails.logger.warn('Attempted to attach a submission to cruise with non-existant data directory')
            raise 'Data directory non-existant'
        end

        submission_public_path = Submission.public_file_path(submission)
        submission_path = $submission_root.join(submission_public_path[13..-1])

        if not File.file?(submission_path)
            Rails.logger.warn("Submission file #{submission_path} does not exist.")
            raise 'No submission file'
        end

        # Ensure Queue directory exists
        queue_path = File.join(data_dir, 'Queue/unprocessed')

        # Let's make it special for this submission
        submission_subdir = File.basename(File.dirname(submission_path))
        queue_path = File.join(queue_path, submission_subdir)

        Rails.logger.info("Queue path: #{queue_path}")

        if not File.directory?(queue_path)
            if File.exists?(queue_path)
                Rails.logger.warn("Queue directory exists but is not a directory.")
                raise 'Bad queue directory'
            else
                FileUtils.mkdir_p(queue_path)
            end
        end

        Rails.logger.debug("Copying submitted file into queue directory.")

        # copy the submitted file into queue directory
        submission_basename = File.basename(submission_path)

        Rails.logger.debug("submitted file: #{submission_basename}")

        if submission_basename =~ /^multiple_files\.\d+\.zip/
            # Unzip the submission file
            noop = Proc.new {}
            Zip::ZipFile.open(submission_path) do |zf|
                zf.each do |entry|
                    Rails.logger.debug("extracting #{entry.name}")
                    begin
                        entry.extract(File.join(queue_path, entry.name), &noop)
                    rescue Zip::ZipDestinationFileExistsError => e
                        Rails.logger.info("#{entry.name} exists. skipping.")
                    end
                end
            end
        else
            Rails.logger.debug("copying #{submission_path}")
            FileUtils.cp(submission_path, queue_path)
        end

        Rails.logger.debug("Creating queue entry for each file copied/extracted.")
        Rails.logger.debug("opts: #{opts.inspect}")

        # Create queue entry for each file
        notes = opts['notes'] || ''
        parameters = opts['parameters'] || ''
        documentation = opts['documentation'] == 'on'
        queue_files = []
        Dir.foreach(queue_path) do |filename|
            if filename == '.' or filename == '..'
                next
            end
            qf = QueueFile.new(
                :Name => filename,
                :DateRecieved => submission.submission_date,
                :DateMerged => 0,
                :ExpoCode => cruise.ExpoCode,
                :Merged => 0,
                :Contact => submission.name,
                :UnprocessedInput => File.join(queue_path, filename),
                :Action => submission.action,
                :CCHDOContact => user.username,
                :Notes => notes,
                :Parameters => parameters,
                :hidden => 0,
                :documentation => documentation,
                :submission_id => submission.id
                )
            qf.save
            Rails.logger.debug("qf #{qf.inspect}")
            queue_files << qf
        end

        Rails.logger.debug("Creating history note for cruise")

        # Create history note
        event_note = "The following files are now available online under "
        event_note += "'Files as received', unprocessed by the CCHDO.\n\n"
        event_note += queue_files.map {|qf| qf.Name}.join("\n")
        history = Event.new(
            :ExpoCode => cruise.ExpoCode,
            :First_Name => 'CCHDO',
            :LastName => 'Staff',
            :Date_Entered => Time.now,
            :Data_Type => parameters,
            :Action => 'Website Update',
            :Summary => "Available under 'Files as received'",
            :Note => event_note
            )
        history.save

        submission.assimilated = true
        submission.save

        return history
    end
end
