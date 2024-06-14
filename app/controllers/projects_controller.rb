class ProjectsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_workspace_or_parent, only: [:new, :create]
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  def show
  end

  def new
    @project = @parent.is_a?(Project) ? @parent.projects.build : @parent.projects.build
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@parent, :new_project_form), 
          partial: 'projects/form', 
          locals: { project: @project, parent: @parent }
        )
      end
    end
  end

  def create
    Rails.logger.info "Creating a new project"
    @project = @parent.is_a?(Project) ? @parent.projects.build(project_params) : @parent.projects.build(project_params)
    @project.workspace = @parent.is_a?(Workspace) ? @parent : @parent.workspace if @parent.is_a?(Workspace)
    
    respond_to do |format|
      if @project.save
        format.html { redirect_to @parent.is_a?(Project) ? @parent : @parent }
        format.turbo_stream
      else
        format.html { render 'new' }
        format.turbo_stream { render 'new' }
      end
    end
  end

  def edit
  end

  def update
    Rails.logger.info "Updating project with ID: #{@project.id}"
    if @project.update(project_params)
      redirect_to @project
    else
      render 'edit'
    end
  end

  def destroy
    Rails.logger.info "Destroying project with ID: #{@project.id}"
    @project.destroy
    redirect_to workspaces_path
  end

  private

  def set_workspace_or_parent
    if params[:workspace_id]
      @parent = Workspace.find(params[:workspace_id])
      Rails.logger.info "Workspace set with ID: #{@parent.id}"
    elsif params[:project_id]
      @parent = Project.find(params[:project_id])
      @workspace = find_workspace(@parent)
      Rails.logger.info "Parent project set with ID: #{@parent.id}"
    end
  end

  def set_project
    if params[:id]
      @project = Project.find(params[:id])
      @workspace = find_workspace(@project) if @project
      Rails.logger.info "Project set with ID: #{@project.id} and workspace ID: #{@workspace.id}"
    end
  end

  def project_params
    params.require(:project).permit(:name, :parent_project_id)
  end

  def find_workspace(project)
    Rails.logger.info "Finding workspace for project ID: #{project.id}"
    if project.workspace
      Rails.logger.info "Workspace found directly for project ID: #{project.id} with workspace ID: #{project.workspace.id}"
      return project.workspace
    elsif project.parent_project
      Rails.logger.info "Recursively finding workspace for parent project ID: #{project.parent_project.id}"
      return find_workspace(project.parent_project)
    else
      Rails.logger.info "No workspace found for project ID: #{project.id}"
      return nil
    end
  end
end