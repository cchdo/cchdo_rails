desc "Remove HOT numbers from groups and correct BATS lines"
task :collapse_timeseries_groups => :environment do
  environment = ENV['env'] || 'development'

  $stderr.puts "ENVIRONMENT: #{environment}"

  RAILS_ENV = environment

  cruises = Cruise.find_all_by_Program('HOT')

  correct_group = 'Timeseries,Pacific,Repeat,HOT'

  cruises.reject! do |x|
    x.Group == correct_group
  end

  begin
    correct_collections = Cruise.find_by_Group(correct_group).collections
  rescue
    correct_collections = []
  end

  cruises.each do |x|
    x.Line = 'PRS02'
    x.Group = correct_group
    x.collections = correct_collections
    x.save!
  end

  correct_group = 'Timeseries,Atlantic,Repeat,BATS'
  cruises = Cruise.find_all_by_Program('BATS')

  cruises.reject! do |x|
    x.Group == correct_group
  end

  begin
    correct_collections = Cruise.find_by_Group(correct_group).collections
  rescue
    correct_collections = []
  end

  cruises.each do |x|
    x.Line = 'ARS01'
    x.Group = correct_group
    x.collections = correct_collections
    x.save!
  end

  collections = Collection.all(:conditions => ['Name LIKE ?', 'HOT-%'])
  collections.each do |x|
    unless x.cruises.empty?
      $stderr.puts("Collection #{x.id} #{x.Name} has cruises.")
    end
    x.cruises = []
    x.save!
    x.delete()
  end

end
