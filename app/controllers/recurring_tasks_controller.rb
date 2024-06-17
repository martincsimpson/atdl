class RecurringTasksController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_recurring_task, only: [:edit, :update, :destroy, :mark_done, :mark_failed]

  def index
    @recurring_tasks = RecurringTask.all
  end

  def new
    @recurring_task = RecurringTask.new
  end

  def create
    @recurring_task = RecurringTask.new(recurring_task_params)
    if @recurring_task.save
      redirect_to recurring_tasks_path, notice: 'Recurring task was successfully created.'
    else
      render :new
    end
  end

  def mark_done
    @recurring_task.done_for_today!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@recurring_task), partial: 'recurring_tasks/recurring_task', locals: { recurring_task: @recurring_task }) }
      format.html { redirect_to recurring_tasks_today_path, notice: 'Recurring task marked as done for today.' }
    end
  end

  def mark_failed
    @recurring_task.failed_for_today!
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@recurring_task), partial: 'recurring_tasks/recurring_task', locals: { recurring_task: @recurring_task }) }
      format.html { redirect_to recurring_tasks_today_path, notice: 'Recurring task marked as failed for today.' }
    end
  end


  def edit
  end

  def update
    if @recurring_task.update(recurring_task_params)
      redirect_to recurring_tasks_path, notice: 'Recurring task was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @recurring_task.destroy
    redirect_to recurring_tasks_path, notice: 'Recurring task was successfully deleted.'
  end

  private

  def set_recurring_task
    @recurring_task = RecurringTask.find(params[:id])
  end

  def recurring_task_params
    params.require(:recurring_task).permit(:name, :schedule)
  end
end