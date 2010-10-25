module ByOceanHelper
  def get(cruise)
    return Cruise.find(:first, :conditions => ["ExpoCode = ?", cruise.ExpoCode])
  end
end
