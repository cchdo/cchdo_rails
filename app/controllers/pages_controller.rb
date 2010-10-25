class PagesController < ApplicationController

  def home
    excluded_filetypes = ['directory', 'Small Plot', 'Large Plot']
    sql_excluded_filetypes = excluded_filetypes.map {|f| "FileType != ?"}
    recently_edited_cruises = Document.all(
      :select => "DISTINCT ExpoCode",
      :conditions => [
        (['ExpoCode IS NOT NULL',
          "ExpoCode != 'NULL'",
          "ExpoCode != ''",
          "ExpoCode != 'no_expocode'",
         ] + sql_excluded_filetypes
        ).join(' AND ')] + excluded_filetypes,
      :order => 'LastModified DESC',
      :limit => 5
    )

    @recent = recently_edited_cruises.map do |d|
      d = Document.find_by_ExpoCode(d.ExpoCode, :select => 'ExpoCode,LastModified', :order => 'LastModified DESC')
      info = {
        :expocode => d.ExpoCode,
        :last_modified => d.LastModified,
        :begin_date => 'Unknown', 
        :line => 'NON', 
        :ship => 'Unknown', 
        :map => nil
      }
      if cruise = Cruise.find_by_ExpoCode(d.ExpoCode)
        info[:begin_date] = cruise.Begin_Date if cruise.Begin_Date
        info[:line] = cruise.Line if cruise.Line
        info[:ship] = cruise.Ship_Name if cruise.Ship_Name
        map = Document.first(:conditions => {:ExpoCode => d.ExpoCode, :FileType => 'Small Plot'})
        info[:map] = map.FileName if map and map.FileName
      end
      info
    end
  end

end
