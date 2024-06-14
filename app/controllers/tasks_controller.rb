class TasksController < ApplicationController
  include ActionView::RecordIdentifier
  include ApplicationHelper

  before_action :set_project_or_task, only: [:new, :create]
  before_action :set_task, only: [:show, :edit, :update, :update_status]

  def inbox
    @tasks = Task.where(workflow_state: nil)
  end

  def today
    @tasks_scope = Task.where('(snoozed_until IS NULL OR snoozed_until <= ?) AND workflow_state NOT IN (?, ?)', Date.today, 'done', 'dropped')
    @workspaces = Workspace.includes(projects: { tasks: :tasks }).all
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
    params.require(:task).permit(:name, :parent_task_id, :delegated_to, :snoozed_until, :deferred_reason)
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