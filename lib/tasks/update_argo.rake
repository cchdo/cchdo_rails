require 'builder'
task :update_argo => :environment do
  # rake --silent full_kml RAILS_ENV=production > output.kml

  class Cruise < ActiveRecord::Base
    has_one :track_line, :primary_key => 'ExpoCode', :foreign_key => 'ExpoCode'
  end

  afs = Argo::File.find_all_by_display(true)
  for af in afs
    af.display = false
    af.content_type = 1
    af.save
  end

  docs = Document.all(
    :conditions => ['FileType = ? AND LastModified > ?', 'NetCDF CTD', '2011-10-31'])
  for doc in docs
    doc
    af = Argo::File.new(
      :ExpoCode => doc.ExpoCode,
      :description => 'http://cchdo.ucsd.edu/cruise/' + (doc.ExpoCode || '') + \
        "\n" + doc.FileName,
      :display => true,
      :size => 0,
      :filename => File.basename(doc.FileName),
      :content_type => 2
    )
    af.save
  end

end

