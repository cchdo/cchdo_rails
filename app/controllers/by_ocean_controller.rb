include DataAccessHelper
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
        Document.find(:all, :select=>"DISTINCT ExpoCode").each do |document|
            documents << document.ExpoCode
        end

        order_by = "area, cruises.Begin_Date ASC"

        @indian_basin = SpatialGroups.find(:all, :include => {:cruise => {:contact_cruises => :contact}}, :conditions => ["indian = ? AND atlantic = ? AND southern = ?", "1", "0", "0"], :order => order_by)
        filter_sgroup_no_docs(documents, @indian_basin)
        @indian_basin = group_spatial_groups(@indian_basin)

        @atlantic_basin = SpatialGroups.find(:all, :include => {:cruise => {:contact_cruises => :contact}}, :conditions => ["indian = ? AND atlantic = ?", "1", "1"], :order => order_by)
        filter_sgroup_no_docs(documents, @atlantic_basin)
        @atlantic_basin = group_spatial_groups(@atlantic_basin)

        @southern_basin = SpatialGroups.find(:all, :include => {:cruise => {:contact_cruises => :contact}}, :conditions => ["indian = ? AND atlantic = ? AND southern = ?", "1", "0", "1"], :order => order_by)
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
            if not grouped[sgroup.area]
                grouped[sgroup.area] = [sgroup]
            end
            if not grouped[sgroup.area].include?(sgroup)
                grouped[sgroup.area] << sgroup
            end
        end
        grouped
    end
end
