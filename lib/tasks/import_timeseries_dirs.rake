require 'fileutils'
require 'json'
require 'date'

desc "Import Timeseries (such as BATS or HOT) directories"
task :import_timeseries_dirs => :environment do
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

  dir = ENV['dir']
  unless dir
    $stderr.puts "Please specify the directory containing the directories "
                 "to import."
    exit 1
  end

  ts = ENV['ts'] || ENV['timeseries']
  unless ts
    $stderr.puts "Please specify the timeseries acronym."
    exit 2
  end

  def escape(x, sym=',', esc='|')
    i = x.index(esc)
    while i
      x.insert(i, esc)
      i = x.index(esc, i + 2)
    end

    i = x.index(sym)
    while i
      x.insert(i, esc)
      i = x.index(sym, i + 2)
    end
    x
  end

  def serialize(l)
    if l.is_a?(Array)
      l.map {|x| escape(x, ',')}.join(',')
    else
      l
    end
  end

  def serialize_or_nil(l)
    if s = serialize(l) and not s.blank?
      s
    else
      nil
    end
  end

  TIMESERIES_INFOS = {
    'HOT' => {
      #'root' => '/data/co2clivar/pacific/hot/prs2',
      'root' => '/Users/myshen/Documents/timeseries/testroot/hot',
      'line' => 'PRS02',
      'country' => 'USA',
      'groups' => ['Timeseries', 'Pacific', 'Repeat', 'HOT']
    },
    'BATS' => {
      #'root' => '/data/co2clivar/atlantic/bats/ars01',
      'root' => '/Users/myshen/Documents/timeseries/testroot/bats',
      'line' => 'ARS01',
      'country' => 'BM',
      'groups' => ['Timeseries', 'Atlantic', 'Repeat', 'BATS']
    }
  }

  def get_info(ts, path)
    orig_dir = File.join(path, 'original')
    acq_dir = ''
    Dir.foreach(orig_dir) do |x|
      if x =~ /ACQUISITION$/
        acq_dir = File.join(orig_dir, x)
        break
      end
    end
    metadata_path = File.join(acq_dir, 'metadata.json')
    metadata = JSON.parser.new(File.open(metadata_path, 'r').read).parse

    if metadata['ship'] =~ /^R\/V\s+(.*)/
      metadata['ship'] = $1
    end
    if ts == 'HOT'
      if metadata['ship'] == 'K-O-K'
          metadata['ship'] = "Ka'Imikai-O-Kanaloa"
      end
      if metadata['ship'] =~ /Knorr/i
        metadata['ship'] = metadata['ship'].upcase
      end
      metadata['chiscis'].map! do |x|
        if x == 'Mandujano'
          'Santiago-Mandujano'
        else
          x
        end
      end

      # TODO maybe might have to override some chiscis
    elsif ts == 'BATS'
      if pis = metadata['pis']
        metadata['chiscis'] = pis
      end
    end
    metadata
  end

  def get_contacts(names, ts)
    if ts == 'HOT'
      contacts = names.map do |x|
        Contact.find_by_LastName(x) or x
      end
      contacts
    else
      names
    end
  end

  def get_groups(groups)
    groups.map do |x|
      Collection.find_by_Name(x) or x
    end.reject do |x|
      not x.is_a?(Collection)
    end
  end

  def import_cruise_dir(cruise_path, ts, timeseries_info)
    cruise_dir = File.basename(cruise_path)

    ts_root = timeseries_info['root']

    # 1. Copy directory in its entirety into CCHDO data tree.

    # Ensure the timeseries root exists.
    unless File.directory?(ts_root)
      FileUtils.mkdir_p(ts_root)
      FileUtils.chmod(0775, ts_root)
    end

    # Ensure the directory doesn't already exist in the timeseries root.
    if File.exist?(File.join(ts_root, cruise_dir))
      $stderr.puts "There is already something in the timeseries root " + 
                   "#{ts_root} called #{cruise_dir}."
      $stderr.puts "Not copying."
    else
      FileUtils.cp_r(cruise_path, ts_root, :preserve => true)
    end

    # 2. Ensure permissions for directory (and subdirs) are okay.

    FileUtils.chmod(0664, Dir.glob(File.join(ts_root, cruise_dir, '*')) - [File.join(ts_root, cruise_dir, 'original')])
    FileUtils.chmod(0775, File.join(ts_root, cruise_dir))

    # 3. Make Cruise entry in cruises

    expocode_file = File.join(cruise_path, 'ExpoCode')
    unless File.file?(expocode_file)
      $stderr.puts "No ExpoCode file found in cruise directory #{cruise_path}."
      return false
    end
    expocode = File.open(expocode_file, 'r').read().rstrip()

    info = get_info(ts, cruise_path)

    cruise = Cruise.find_or_create_by_ExpoCode(expocode)
    cruise.attributes = {
      :Line => timeseries_info['line'],
      :Chief_Scientist => serialize_or_nil(info['chiscis']),
      :Begin_Date => info['date_start'],
      :EndDate => info['date_end'],
      :Ship_Name => info['ship'],
      :Alias => serialize_or_nil(info['aliases']),
      :Country => timeseries_info['country'],
      :Group => serialize_or_nil(timeseries_info['groups']),
      :Program => ts
    }

    contacts = get_contacts(info['chiscis'], ts).reject {|x| not x.is_a?(Contact)}
    cruise.collections = get_groups(timeseries_info['groups'])
    cruise.contacts = contacts

    event = Event.find_or_create_by_Action('Data Acquired/Converted')
    event.attributes = {
      :ExpoCode => expocode,
      :First_Name => 'Matthew',
      :LastName => 'Shen',
      :Data_Type => 'CTD',
      :Date_Entered => Date.today,
      :Summary => 'Data acquired/converted',
      :Note => "Translated HOT sumfiles to WOCE sumfiles. Zipped WOCE CTDs. " + 
               "Created Exchange and NetCDF BOT and CTDs. Plotted navs and cut thumbnails."
    }

    ActiveRecord::Base.transaction do
      p cruise
      p event

      # 4. cchdo_update.rb absolute_path_to_dir
      #    This should do all the document insertions.

      command = "cchdo_update.rb #{File.join(ts_root, cruise_dir)}"
      `#{command}`

      # 5. Make history entry
      cruise.save!
      event.save!

      if cc = cruise.contact_cruises.last
        cc.function = 'Chief Scientist'
        cc.save!
      end
    end
  end

  timeseries_info = TIMESERIES_INFOS[ts]
  unless timeseries_info
    $stderr.puts "The timeseries acronym you gave is unrecognized.\n" + 
                 "The cruise entry would be missing a lot of metadata so we " +
                 "will not continue."
    exit 4
  end

  Dir.foreach(dir) do |cruise_dir|
    next if ['.', '..'].include?(cruise_dir)
    import_cruise_dir(File.join(dir, cruise_dir), ts, timeseries_info)
  end
end
