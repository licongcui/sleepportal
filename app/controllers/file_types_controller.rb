class FileTypesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_system_admin

  def index
    @file_types = current_user.file_types.all
  end

  def show
    @file_type = current_user.file_types.find_by_id(params[:id])
    redirect_to root_path unless @file_type
  end

  def new
    @file_type = current_user.file_types.new
  end

  def edit
    @file_type = current_user.file_types.find_by_id(params[:id])
    redirect_to root_path unless @file_type
  end

  def create
    @file_type = current_user.file_types.new(params[:file_type])

    if @file_type.save
      redirect_to @file_type, notice: 'File type was successfully created.'
    else
      render action: "new"
    end
  end

  def update
    @file_type = current_user.file_types.find_by_id(params[:id])
    
    unless @file_type
      redirect_to root_path
      return
    end
    
    if @file_type.update_attributes(params[:file_type])
      redirect_to @file_type, notice: 'File type was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @file_type = current_user.file_types.find_by_id(params[:id])
    
    if @file_type
      @file_type.destroy
      redirect_to file_types_path
    else
      redirect_to root_path
    end
  end
end