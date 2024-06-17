class TasksController < ApplicationController
  include ActionView::RecordIdentifier
  include ApplicationHelper

  before_action :set_project_or_task, only: [:new, :create, :create_inbox_task]
  before_action :set_task, only: [:show, :edit, :update, :update_status, :clear_snooze, :move_form, :move]

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
    @tasks_scope = :today
    @workspaces = Workspace.includes(projects: { tasks: :tasks }).all
    @recurring_tasks = RecurringTask.all.select { |r| r.scheduled_today? && !r.complete_for_today? }
  end

  def review
    @tasks_scope = :review
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

    # We're updating only snooze
    if params[:event].nil? && params[:snoozed_until]
      @task.update_snooze_date(parse_snooze_date(params[:snoozed_until]))
    else
      event = params[:event].to_sym
      if @task.available_transitions.include?(event)
        if event == :delegate
          @task.delegate_task(params[:delegated_to], params[:snoozed_until], apply_to_all_subtasks: params[:apply_to_all_subtasks] == '1')
        elsif event == :defer
          @task.defer_task(params[:deferred_reason], params[:snoozed_until], apply_to_all_subtasks: params[:apply_to_all_subtasks] == '1')
        else
          @task.process_event!(event)
        end
      else
        head :unprocessable_entity
      end
    end

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
  end

  def clear_snooze
    @task.update(snoozed_until: nil)
    respond_to do |format|
      format.html { redirect_to @task, notice: 'Snooze date was successfully cleared.' }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@task),
          partial: 'tasks/task',
          locals: { task: @task }
        )
      end
    end
  end

  def move_form
    render turbo_stream: turbo_stream.replace(dom_id(@task, :move_form), partial: "tasks/move_form", locals: { task: @task })
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

  def bulk_import
    inbox_project = Project.find_by(name: 'Inbox')

    task_list = params[:task_list]
    return if task_list.blank?

    tasks = parse_tasks(task_list)

    create_tasks(tasks, inbox_project)

    redirect_to inbox_path, notice: 'Tasks imported successfully.'
  end

  private

  def parse_tasks(task_list)
    task_lines = task_list.split("\n")
    tasks = []
    task_lines.each do |line|
      depth = line[/\A\s*/].size / 4
      name = line.strip
      tasks << { name: name, depth: depth }
    end
    tasks
  end

  def create_tasks(tasks, parent_project)
    parent_stack = [{ project: parent_project, depth: -1 }]
    tasks.each do |task|
      while task[:depth] <= parent_stack.last[:depth]
        parent_stack.pop
      end
      parent = parent_stack.last[:project]
      new_task = parent.tasks.create(name: task[:name])
      parent_stack.push({ project: new_task, depth: task[:depth] })
    end
  end

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
end