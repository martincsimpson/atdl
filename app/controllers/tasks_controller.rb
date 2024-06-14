class TasksController < ApplicationController
  include ActionView::RecordIdentifier
  include ApplicationHelper

  before_action :set_project_or_task, only: [:new, :create]
  before_action :set_task, only: [:show, :edit, :update, :update_status]

  def new
    @task = @parent.tasks.build
    logger.debug "Rendering new form for task with parent: #{@parent.inspect}"
    respond_to do |format|
      format.html
      format.turbo_stream do
        logger.debug "Responding with Turbo Stream for new task form"
        render turbo_stream: turbo_stream.replace(
          dom_id(@parent, :new_task_form), 
          partial: 'tasks/form', 
          locals: { task: @task, parent: @parent, project: find_root_project(@parent) }
        )
      end
    end
  end

  def create
    @task = @parent.tasks.build(task_params)
    logger.debug "Creating task with params: #{task_params.inspect}"

    respond_to do |format|
      if @task.save
        logger.debug "Task created successfully: #{@task.inspect}"
        format.html { redirect_to @parent }
        format.turbo_stream do
          logger.debug "Responding with Turbo Stream for task creation"
          render turbo_stream: turbo_stream.append(
            dom_id(@parent, :tasks),
            partial: 'tasks/task',
            locals: { task: @task, parent: @parent }
          ) + turbo_stream.replace(
            dom_id(@parent, :new_form),
            ""
          )
        end
      else
        logger.debug "Task creation failed: #{@task.errors.full_messages.inspect}"
        format.html { render :new }
        format.turbo_stream do
          logger.debug "Responding with Turbo Stream for task creation failure"
          render turbo_stream: turbo_stream.replace(
            dom_id(@parent, :new_form), 
            partial: 'tasks/form', 
            locals: { task: @task, parent: @parent, project: find_root_project(@parent) }
          )
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @task.update(task_params)
        logger.debug "Task updated successfully: #{@task.inspect}"
        format.html { redirect_to @task }
        format.turbo_stream do
          logger.debug "Responding with Turbo Stream for task update"
          render turbo_stream: turbo_stream.replace(
            dom_id(@task),
            partial: 'tasks/task',
            locals: { task: @task, parent: @task.parent_task || @task.project }
          )
        end
      else
        logger.debug "Task update failed: #{@task.errors.full_messages.inspect}"
        format.html { render :edit }
        format.turbo_stream do
          logger.debug "Responding with Turbo Stream for task update failure"
          render turbo_stream: turbo_stream.replace(
            dom_id(@task),
            partial: 'tasks/form',
            locals: { task: @task, parent: @task.parent_task || @task.project }
          )
        end
      end
    end
  end

  def update_status
    event = params[:event].to_sym
    logger.debug "Processing event: #{event} for task: #{@task.inspect}"
    if @task.available_transitions.include?(event)
      @task.process_event!(event)
      logger.debug "Task status updated to: #{@task.workflow_state}"
      respond_to do |format|
        format.turbo_stream do
          logger.debug "Responding with Turbo Stream for task status update"
          render turbo_stream: turbo_stream.replace(
            dom_id(@task),
            partial: 'tasks/task',
            locals: { task: @task, parent: @task.parent_task || @task.project }
          )
        end
        format.html { redirect_to @task.parent_task || @task.project }
      end
    else
      logger.debug "Invalid event: #{event} for task: #{@task.inspect}"
      head :unprocessable_entity
    end
  end

  private

  def set_project_or_task
    if params[:project_id]
      @parent = Project.find(params[:project_id])
    elsif params[:task_id]
      @parent = Task.find(params[:task_id])
    end
    logger.debug "Set parent: #{@parent.inspect}"
  end

  def set_task
    @task = Task.find(params[:id])
    logger.debug "Set task: #{@task.inspect}"
  end

  def task_params
    params.require(:task).permit(:name, :parent_task_id)
  end
end