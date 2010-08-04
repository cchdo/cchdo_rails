class ParameterDescriptionsController < ApplicationController
  def index
    @parameters = ParameterDescriptions.find(:all,:order => ["Parameter"])
    @primary = ParameterGroup.find(:first, :conditions => "`group` = 'CCHDO Primary Parameters'").parameters
    @secondary = ParameterGroup.find(:first, :conditions => "`group` = 'CCHDO Secondary Parameters'").parameters
    @tertiary = ParameterGroup.find(:first, :conditions => "`group` = 'CCHDO Tertiary Parameters'").parameters
  end
end
