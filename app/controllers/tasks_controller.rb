class TasksController < ApplicationController
  include ActionView::RecordIdentifier
  include ApplicationHelper

  before_action :set_project_or_task, only: [:new, :create, :create_inbox_task]
  before_action :set_task, only: [:show, :edit, :update, :update_status, :move]

  def inbox
    @inbox_workspace = Workspace.find_by(name: 'Inbox')
    if @inbox_workspace
      @inbox_project = @inbox_workspace.projects.find_by(name: 'Inbox')
      if @inbox_project
        @tasks = @inbox_project.tasks.where(workflow_state: nil)
      else
        @tasks = Task.none # No tasks if the project does not exist
      end
    else
      @tasks = Task.none # No tasks if the workspace does not exist
    end
  end

  def create_inbox_task
    inbox_workspace = Workspace.find_by(name: 'Inbox')
    if inbox_workspace
      inbox_project = inbox_workspace.projects.find_by(name: 'Inbox')
      @task = inbox_project.tasks.build(task_params)
      if @task.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              dom_id(inbox_workspace, :projects_container),
              partial: 'projects/project',
              locals: { project: inbox_project, tasks_scope: nil }
            )    
          end
        end
      else
        respond_to do |format|
          format.turbo_stream
        end
      end
    end
  end

  def today
    @tasks_scope = Task.where('(snoozed_until IS NULL OR snoozed_until <= ?) AND workflow_state NOT IN (?, ?)', Date.today, 'done', 'dropped')
    @workspaces = Workspace.includes(projects: { tasks: :tasks }).all
    @recurring_tasks = RecurringTask.all.select { |r| r.scheduled_today? && !r.done_for_today? }
  end

  def review
    @tasks_scope = Task.where('(snoozed_until IS NULL OR snoozed_until <= ?) AND workflow_state NOT IN (?, ?)', Date.today, 'done', 'dropped')
    @workspaces = Workspace.includes(projects: { tasks: :tasks }).all
  end

  def master
    @tasks_scope = nil
    @workspaces = Workspace.includes(projects: { tasks: :tasks }).all
  end

  def new
    @task = @parent.tasks.build
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@parent, :new_task_form),
          partial: 'tasks/form',
          locals: { task: @task, parent: @parent }
        )
      end
    end
  end

  def create
    @task = @parent.tasks.build(task_params)
    respond_to do |format|
      if @task.save
        format.html { redirect_to @parent }
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            dom_id(@parent, :tasks),
            partial: 'tasks/task',
            locals: { task: @task, parent: @parent }
          ) + turbo_stream.replace(
            dom_id(@parent, :new_task_form),
            ""
          )
        end
      else
        format.html { render :new }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@parent, :new_task_form),
            partial: 'tasks/form',
            locals: { task: @task, parent: @parent }
          )
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to @task }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@task),
            partial: 'tasks/task',
            locals: { task: @task, parent: @task.parent_task || @task.project }
          )
        end
      else
        format.html { render :edit }
        format.turbo_stream do
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
    if @task.available_transitions.include?(event)
      if event == :delegate
        @task.update(delegated_to: params[:delegated_to], snoozed_until: parse_snooze_date(params[:snoozed_until]))
      elsif event == :defer
        @task.update(deferred_reason: params[:deferred_reason], snoozed_until: parse_snooze_date(params[:snoozed_until]))
      end
      @task.process_event!(event)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@task),
            partial: 'tasks/task',
            locals: { task: @task, parent: @task.parent_task || @task.project }
          )
        end
        format.html { redirect_to @task.parent_task || @task.project }
      end
    else
      head :unprocessable_entity
    end
  end

  def move
    new_parent_id = params[:new_parent_id]
    if new_parent_id.present?
      if new_parent_id.start_with?('task_')
        @task.update(parent_task_id: new_parent_id.split('_').last, project_id: nil)
      else
        @task.update(project_id: new_parent_id, parent_task_id: nil)
      end
    end

    respond_to do |format|
      format.html { redirect_to @task, notice: 'Task was successfully moved.' }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@task),
          partial: 'tasks/task',
          locals: { task: @task, parent: @task.parent_task || @task.project }
        )
      end
    end
  end


  private

  def set_project_or_task
    if params[:project_id]
      @parent = Project.find(params[:project_id])
    elsif params[:task_id]
      @parent = Task.find(params[:task_id])
    end
  end

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:name, :parent_task_id, :delegated_to, :snoozed_until, :deferred_reason, :new_parent_id)
  end

  def parse_snooze_date(snooze_option)
    case snooze_option
    when 'tomorrow'
      1.day.from_now
    when 'few_days'
      3.days.from_now
    when 'week'
      1.week.from_now
    when 'month'
      1.month.from_now
    else
      nil
    end
  end
end