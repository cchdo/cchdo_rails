require 'rubygems'

desc "Import Argo Files"
task :import_argo_files => :environment do
    # Environment variables
    # Example: 
    #   $ rake import_timeseries_dirs env=production \
    #     dir=~/Documents/timeseries/hot/data ts=HOT \
    # Required:
    #   dir - path to directory containing the directories to import
    #   ts|timeseries - the timeseries acronym

    environment = ENV['env'] || 'development'

    $stderr.puts "ENVIRONMENT: #{environment}"

    RAILS_ENV = environment

    files = ENV['files']
    unless files
        $stderr.puts "Please specify the files list."
        exit 2
    end
    Argo::File.find_all_by_content_type(3).each do |afile|
        afile.description = afile.filename.gsub("http://cchdo.ucsd.edu", "")
        if afile.description == 'in process'
            afile.description = "in_process"
        end
        afile.save
    end

    File.open(files, "r").each do |line|
        line.rstrip!
        next if line.empty?
        expocode, path, status = line.split(/\s+/)
        next if status == "x"
        $stderr.puts "#{line.inspect} #{status.inspect}"
        if status == "in_process"
            # update the other
            af = Argo::File.find_by_ExpoCode(expocode)
            af.description = path
            af.filename = path
            af.content_type = 4
            $stderr.puts "updated in_process to " + path
        else
            af = Argo::File.new(
                :ExpoCode => expocode,
                :description => path,
                :display => true,
                :size => 0,
                :filename => path,
                :user_id => 1,
                :content_type => 4
            )
            # 4 = AST14
        end
        $stderr.puts af.inspect
        af.save
    end
end
