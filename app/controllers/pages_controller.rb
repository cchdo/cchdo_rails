class PagesController < ApplicationController

  def home
    @recent = Document.recently_edited_expocodes().map do |expocode|
      d = Document.find_by_ExpoCode(
        expocode, :select => 'ExpoCode,LastModified',
        :order => 'LastModified DESC')
      info = {
        :expocode => d.ExpoCode,
        :last_modified => d.LastModified,
        :begin_date => 'Unknown', 
        :line => 'NON', 
        :ship => 'Unknown', 
        :map => nil
      }
      begin
          if d.cruise and cruise = reduce_specifics(d.cruise)
            info[:begin_date] = cruise.Begin_Date if cruise.Begin_Date
            info[:line] = cruise.Line if cruise.Line
            info[:ship] = cruise.Ship_Name if cruise.Ship_Name
            files = cruise.get_files()
            if map = files['small_pic']
              info[:map] = map
            end
          end
      rescue
      end
      info
    end
  end

end
