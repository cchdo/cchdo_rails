class GroupSearchController < ApplicationController
   layout 'standard'
   def index
       if params[:id]
          @group = params[:id]
       elsif params[:query]
          @group = params[:query]
          params[:expanded] = "true"
       else
          @group = "Pacific" #params[:id]
       end
       # grab the groups info from the CruiseGroup table

       @groups = []
       @cruise_groups = []
       @groups << @group
       @cruise_groups << CruiseGroup.find(:first,:conditions => ["`Group` = '#{@group}'"])
       # grab any subgroups that belong to the current group
       if @cruise_groups[0].SubGroups =~ /\w/
         subgroups = @cruise_groups[0].SubGroups.split(',')
         subgroups.each { |group|
           @groups << group
           @cruise_groups << CruiseGroup.find(:first,:conditions => ["`Group` = '#{group}'"])  
         }
       end
       @cruise_hash = Hash.new
       @plot_hash = Hash.new
       for group in @cruise_groups
         cruises = group.Cruises.split(',') 
         cruises.each do |cruise|
           if cruise_row = reduce_specifics(Cruise.find(:first, :conditions => ["`ExpoCode` = '#{cruise}'"]))
             @cruise_hash[cruise] = cruise_row.Line
           end
           if doc_row = Document.find(:first, :conditions => ["`ExpoCode` = '#{cruise}' AND `FileType` = 'Small Plot'"])
             @plot_hash[cruise] = doc_row.FileName
           end
         end
       end
   end
end
