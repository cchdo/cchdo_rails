class ParameterDescriptionsController < ApplicationController
  def index
    @parameters = ParameterDescriptions.find(:all,:order => ["Parameter"])
    @primary = ParameterGroup.find(:first, :conditions => "`group` = 'CCHDO Primary Parameters'").parameters.split(',')
    @secondary = ParameterGroup.find(:first, :conditions => "`group` = 'CCHDO Secondary Parameters'").parameters.split(',')
    @tertiary = ParameterGroup.find(:first, :conditions => "`group` = 'CCHDO Tertiary Parameters'").parameters.split(',')
  end
end
