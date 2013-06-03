class ByOceanController < ApplicationController
def arctic 
  @documents = []
  Document.find(:all, :select=>"DISTINCT ExpoCode").each do |document|
    @documents << document.ExpoCode
  end
  @cruises = reduce_specifics(Cruise.find(:all, :conditions => ["`Group` LIKE ?", "%arctic%"], :order=>"Line, Begin_Date ASC"))
  @cruises.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)}
end

def southern
  @documents =[]
  Document.find(:all, :select=>"ExpoCode").each do |document|
    @documents << document.ExpoCode
  end
  @southern_basin = reduce_specifics(Cruise.find(:all, :conditions => ["`Group` LIKE ? AND (`Line` LIKE ?)", "%southern%", "S%"], :order=>"Line, Begin_Date ASC"))
  @southern_basin.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)}

  @indian_basin = reduce_specifics(Cruise.find(:all, :conditions => ["`Group` LIKE ? AND (`Line` LIKE ? OR `Line` LIKE ?)", "%southern%", "I%", "AIS%"], :order=>"Line, Begin_Date ASC"))
  @indian_basin.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)} 

  @pacific_basin = reduce_specifics(Cruise.find(:all, :conditions => ["`Group` LIKE ? AND (`Line` LIKE ? OR `Line` LIKE ?)", "%southern%", "P%", "AAI%"], :order=>"Line, Begin_Date ASC"))
  @pacific_basin.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)}

  @atlantic_basin = reduce_specifics(Cruise.find(:all, :conditions => ["`Group` LIKE ? AND (`Line` LIKE ? OR `Line` LIKE ? OR `Line` LIKE ? )", "%southern%", "A__", "AR%", "AJ%"], :order=>"Line, Begin_Date ASC"))
  @atlantic_basin.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)}
end 

    def indian 
        documents = []
        Document.find(:all, :select=>"ExpoCode").each do |document|
            documents << document.ExpoCode
        end

        joined = "SELECT DISTINCT * FROM (cruises INNER JOIN spatial_groups " + 
            "ON spatial_groups.ExpoCode = cruises.ExpoCode) WHERE" 
        ind = "indian = ?"
        atl = "atlantic = ?"
        sou = "southern = ?"
        order_by = "ORDER BY area, Begin_Date ASC"

        @indian_basin = SpatialGroups.find_by_sql(
            ["#{joined} #{ind} AND #{atl} AND #{sou} #{order_by}",'1','0','0'])
        filter_sgroup_no_docs(documents, @indian_basin)
        @indian_basin = group_spatial_groups(@indian_basin)

        @atlantic_basin = SpatialGroups.find_by_sql(
            ["#{joined} #{ind} AND #{atl} #{order_by}",'1','1'])
        filter_sgroup_no_docs(documents, @atlantic_basin)
        @atlantic_basin = group_spatial_groups(@atlantic_basin)

        @southern_basin = SpatialGroups.find_by_sql(
            ["#{joined} #{ind} AND #{atl} AND #{sou} #{order_by}",'1','0','1'])
        filter_sgroup_no_docs(documents, @southern_basin)
        @southern_basin = group_spatial_groups(@southern_basin)
    end

    private

    def filter_sgroup_no_docs(documents, sgroups)
        sgroups.delete_if {|cruise| !documents.include?(cruise.ExpoCode)} 
    end

    # Take a list of SpatialGroups and convert to a Hash with area name mapped
    # to a list of SpatialGroups in the same order they were found.
    def group_spatial_groups(sgs)
        grouped = ActiveSupport::OrderedHash.new()
        for sgroup in sgs
            begin
                if not grouped[sgroup.area].include?(sgroup)
                    grouped[sgroup.area] << sgroup
                end
            rescue
                grouped[sgroup.area] = [sgroup]
            end
        end
        grouped
    end
end
