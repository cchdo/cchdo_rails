class Staff::ChangedFilesController < ApplicationController
  def index
    @files = ChangedFile.all
  end
end
