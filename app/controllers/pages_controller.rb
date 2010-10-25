class PagesController < ApplicationController

  def home
    @recent = Document.recently_edited_expocodes().map do |expocode|
      d = Document.find_by_ExpoCode(expocode, :select => 'ExpoCode,LastModified', :order => 'LastModified DESC')
      info = {
        :expocode => d.ExpoCode,
        :last_modified => d.LastModified,
        :begin_date => 'Unknown', 
        :line => 'NON', 
        :ship => 'Unknown', 
        :map => nil
      }
      if cruise = d.cruise
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
