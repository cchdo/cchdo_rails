class Argo::FilesController < ApplicationController
  layout 'standard'

  def index
      redirect_to :controller => '../argo'
  end

  # GET /argo_files/1
  # GET /argo_files/1.xml
  def show
    @file = Argo::File.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @file }
    end
  end

  # GET /argo_files/new
  # GET /argo_files/new.xml
  def new
    @file = Argo::File.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @file }
    end
  end

  # GET /argo_files/1/edit
  def edit
    @file = Argo::File.find(params[:id])
  end

  # POST /argo_files
  # POST /argo_files.xml
  def create
    @file = Argo::File.new(params[:argo_file])

    @file.user = User.find(session[:user])

    respond_to do |format|
      if @file.save
        flash[:notice] = 'Argo::File was successfully created.'
        format.html { redirect_to(@file) }
        format.xml  { render :xml => @file, :status => :created, :location => @file }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /argo_files/1
  # PUT /argo_files/1.xml
  def update
    @file = Argo::File.find(params[:id])

    respond_to do |format|
      if @file.update_attributes(params[:argo_file])
        flash[:notice] = 'Argo::File was successfully updated.'
        format.html { redirect_to(@file) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /argo_files/1
  # DELETE /argo_files/1.xml
  def destroy
    @file = Argo::File.find(params[:id])
    @file.destroy

    respond_to do |format|
      format.html { redirect_to(argo_files_url) }
      format.xml  { head :ok }
    end
  end
end
