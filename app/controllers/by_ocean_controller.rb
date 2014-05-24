include DataAccessHelper
class ByOceanController < ApplicationController

    def arctic 
        @documents = documented_cruises()
        @cruises = spatial_group_cruises(documented_cruises, ["arctic = 1"])
    end

    def southern
        documented_cruises = documented_cruises()
        @southern_basin = spatial_group_cruises(documented_cruises, ["southern = 1 AND indian = 0 AND atlantic = 0 AND pacific = 0"])
        @indian_basin = spatial_group_cruises(documented_cruises, ["southern = 1 AND indian = 1"])
        @pacific_basin = spatial_group_cruises(documented_cruises, ["southern = 1 AND pacific = 1"])
        @atlantic_basin = spatial_group_cruises(documented_cruises, ["southern = 1 AND atlantic = 1"])
    end 

    def indian 
        documented_cruises = documented_cruises()
        @indian_basin = spatial_group_cruises(documented_cruises, ["indian = 1 AND atlantic = 0 AND southern = 0"])
        @atlantic_basin = spatial_group_cruises(documented_cruises, ["indian = 1 AND atlantic = 1"])
        @southern_basin = spatial_group_cruises(documented_cruises, ["indian = 1 AND atlantic = 0 AND southern = 1"])
    end

    private

    def documented_cruises
        cruises = []
        Document.find(:all, :select => "DISTINCT ExpoCode").each do |document|
            cruises << document.ExpoCode
        end
        cruises
    end

    def spatial_group_cruises(documented_cruises, conditions)
        order_by = "area, cruises.Begin_Date ASC"

        groups = SpatialGroups.find(:all,
            :include => :cruise,
            :conditions => conditions, :order => order_by)
        filter_sgroup_no_docs(documented_cruises, groups)
        groups = group_spatial_groups(groups)
    end

    def basin_cruises(documented_cruises, conditions)
        cruises = reduce_specifics(Cruise.find(:all, :conditions => conditions,
            :order=>"Line, Begin_Date ASC"))
        filter_sgroup_no_docs(documented_cruises, cruises)
        cruises
    end

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
