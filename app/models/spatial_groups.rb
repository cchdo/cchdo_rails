class SpatialGroups < ActiveRecord::Base
    has_one :cruise, :primary_key => "ExpoCode", :foreign_key => "ExpoCode"
end
