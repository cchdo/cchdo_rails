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
  @documents =[]
  Document.find(:all, :select=>"ExpoCode").each do |document|
    @documents << document.ExpoCode
  end

joined = "SELECT * FROM (cruises INNER JOIN spatial_groups " + 
"ON spatial_groups.ExpoCode = cruises.ExpoCode) WHERE" 
ind = "indian = ?"
atl = "atlantic = ?"
sou = "southern = ?"
order_by = "ORDER BY area, Begin_Date ASC"

  @indian_basin = SpatialGroups.find_by_sql(["#{joined} #{ind} AND #{atl} AND #{sou} #{order_by}",'1','0','0'])
  @indian_basin.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)} 

  @atlantic_basin = SpatialGroups.find_by_sql(["#{joined} #{ind} AND #{atl} #{order_by}",'1','1'])
  @atlantic_basin.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)} 
  
  @southern_basin = SpatialGroups.find_by_sql(["#{joined} #{ind} AND #{atl} AND #{sou} #{order_by}",'1','0','1'])
  @southern_basin.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)} 








  #@southern_basin = Cruise.find(:all, :conditions => ["`Group` LIKE ? AND (`Line` LIKE ?)", "%indian%", "S%"], :order=>"Line, Begin_Date ASC")
  #@southern_basin.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)}

  #@indian_basin = Cruise.find(:all, :conditions => ["`Group` LIKE ? AND (`Line` LIKE ? OR `Line` LIKE ?)", "%indian%", "I%", "AIS%"], :order=>"Line, Begin_Date ASC")
  #@indian_basin.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)} 

  #@atlantic_basin = Cruise.find(:all, :conditions => ["`Group` LIKE ? AND (`Line` LIKE ? OR `Line` LIKE ? OR `Line` LIKE ? )", "%indian%", "A__", "AR%", "AJ%"], :order=>"Line, Begin_Date ASC")
  #@atlantic_basin.delete_if {|cruise| !@documents.include?(cruise.ExpoCode)}
end
end
