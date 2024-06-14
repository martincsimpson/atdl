class TasksController < ApplicationController
  include ActionView::RecordIdentifier
  include ApplicationHelper

  before_action :set_project_or_task, only: [:new, :create]
  before_action :set_task, only: [:show, :edit, :update, :update_status]

  def new
    @task = @parent.tasks.build
    respond_to do |format|
      format.html
      format.turbo_stream do
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
            locals: { task: @task, parent: @parent, project: find_root_project(@parent) }
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
        delegated_to = params[:delegated_to]
        snoozed_until = parse_snoozed_until(params[:snoozed_until])
        @task.update(delegated_to: delegated_to, snoozed_until: snoozed_until)
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
    params.require(:task).permit(:name, :parent_task_id, :delegated_to, :snoozed_until)
  end

  def parse_snoozed_until(value)
    case value
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