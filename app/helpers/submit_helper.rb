require 'zip/zip'

module SubmitHelper
  def step_header(number, header)
    content_tag(:tr, escape=false) do
      content_tag(:td, escape=false) do
        content_tag(:span, {:class => :step2}, escape=false) do
          'Step' + content_tag(:span, number, :class => :step_number2) + ':'
        end + ' ' + 
        content_tag(:span, header, :class => :step_title)
      end
    end
  end

  def submitted_file_names(file)
    files = [File.basename(file)]
    if File.basename(file) =~ /^#{Submission::MULTI_UPLOAD_FILE_NAME_BASE}\.\d+\.zip$/
      # Maybe this is a bad assumption but if someone bothers to name it as a
      # exactly this type of zip file...I'll call it a duck.
      zip_files = []
      begin
        Zip::ZipFile.foreach(file) do |ze|
          zip_files << ze.name
        end
      rescue Zip::ZipError => e
        return files
      end
      files = zip_files
    end
    files
  end
end
