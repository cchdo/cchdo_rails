class ParameterDescriptionsController < ApplicationController
  def index
    @parameters = ParameterDescriptions.find(:all,:order => ["Parameter"])
  end
end
