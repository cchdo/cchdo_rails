require 'parsedate'
class CruiseNewsController < ApplicationController
  layout false
  def recent_changes
    @recent_changes = Document.find(:all,:conditions => ["FileType != 'Directory'"],:order => "LastModified DESC", :limit => 150)
    response.headers["Type"] = "application/rss+xml"
    @date_list = Hash.new{|@date_list,key| @date_list[key]={}}
    @expo_list = Array.new
    #@expo_list << @recent_changes[0][:ExpoCode]
    for  file_change in @recent_changes
      unless @expo_list.include?("#{file_change.ExpoCode}")
        @expo_list << file_change.ExpoCode
        @date_list[file_change.ExpoCode]["Files"] = String.new
      end
      if file_change.LastModified
         if file_change.LastModified !~ /\//
            d = file_change.LastModified.to_s
            #date_array = ParseDate.parsedate(d)
            #date = DateTime.new(date_array)
            unless file_change.FileType =~ /unrecognized/i
               if file_change.Stamp =~ /\w/
                 @date_list[file_change.ExpoCode]["Files"] << " #{file_change.FileType} (#{file_change.Stamp}),"
               else
                 @date_list[file_change.ExpoCode]["Files"] << " #{file_change.FileType},"
               end
            end
            if cruise = reduce_specifics(Cruise.find(:first,:conditions => ["ExpoCode = '#{file_change.ExpoCode}'"]))
               @date_list[file_change.ExpoCode]["Line"] = cruise.Line
            end
            @date_list[file_change.ExpoCode]["Date"] = Time.parse(d)
         else
           @date_list[file_change.ExpoCode]["Date"] = Time.now
         end
         
      end
    end
  end
  
end
