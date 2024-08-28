class Task < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :parent_task, class_name: 'Task', optional: true
  has_many :tasks, class_name: 'Task', foreign_key: 'parent_task_id', dependent: :destroy

  validates :notes, length: { maximum: 10000 }, allow_blank: true

  include Workflow

  workflow do
    state :new do
      event :start_todo, transitions_to: :todo
      event :drop, transitions_to: :dropped
    end
    state :todo do
      event :start_doing, transitions_to: :doing
      event :defer, transitions_to: :deferred
      event :delegate, transitions_to: :delegated
      event :drop, transitions_to: :dropped
    end
    state :doing do
      event :complete, transitions_to: :done
      event :defer, transitions_to: :deferred
      event :delegate, transitions_to: :delegated
      event :drop, transitions_to: :dropped
    end
    state :deferred do
      event :complete, transitions_to: :done
      event :delegate, transitions_to: :delegated
      event :defer, transitions_to: :deferred
      event :drop, transitions_to: :dropped
    end
    state :delegated do
      event :delegate, transitions_to: :delegated
      event :complete, transitions_to: :done
      event :drop, transitions_to: :dropped
    end
    state :done do
      event :drop, transitions_to: :dropped
    end
    state :dropped

    on_transition do |from, to, triggering_event, *event_args|
      if to == :done
        self.snoozed_until = nil
        self.save
      end
    end
  end

  def load_workflow_state
    self.workflow_state
  end

  def persist_workflow_state(new_value)
    update_column(:workflow_state, new_value)
  end

  def available_transitions
    self.current_state.events.keys
  end

  def parent
    self.parent_task || self.project
  end

  def parent_string
    self.parent.parent_string + " - #{self.name}"
  end

  # Checks to see if we are relevant, or we have any subtasks that are relevant
  def any_task_matching?(scope)
    matches_scope?(scope) || tasks.any? { |sub_task| sub_task.any_task_matching?(scope) }
  end

  # Gets a list of tasks that are either relevant or have children that are relevant
  def tasks_or_subtasks_matching(scope)
    tasks.select { |t| t.matches_scope?(scope) or t.tasks_or_subtasks_matching(scope).any? }
  end

  def matches_scope?(scope)
    case scope
    when :today
      return true if snoozed_until.nil? && current_state != 'done' && current_state != 'dropped'
      return false if current_state == 'done' || current_state == 'dropped'
      return true if snoozed_until.to_date <= Date.today
    when :review
      return false if snoozed_until.nil? || current_state == 'done' || current_state == 'dropped'
      return true if snoozed_until.to_date > Date.today
    else
      return true
    end
  end

  # Delegate the task and optionally apply to all subtasks
  def delegate_task(delegated_to, snoozed_until, apply_to_all_subtasks: false)
    if self.current_state == :new
      self.process_event!(:start_todo)
    end

    if self.current_state != :done and self.current_state != :dropped
      self.update(delegated_to: delegated_to, snoozed_until: parse_snooze_date(snoozed_until))
      self.process_event!(:delegate)
    end

    if apply_to_all_subtasks
      tasks.each do |subtask|
        subtask.delegate_task(delegated_to, snoozed_until, apply_to_all_subtasks: true)
      end
    end
  end

  # Defer the task and optionally apply to all subtasks
  def defer_task(deferred_reason, snoozed_until, apply_to_all_subtasks: false)
    if self.current_state == :new
      self.process_event!(:start_todo)
    end

    if self.current_state != :done and self.current_state != :dropped
      self.update(deferred_reason: deferred_reason, snoozed_until: parse_snooze_date(snoozed_until))
      self.process_event!(:defer)
    end

    if apply_to_all_subtasks
      tasks.each do |subtask|
        subtask.defer_task(deferred_reason, snoozed_until, apply_to_all_subtasks: true)
      end
    end
  end
  
  def update_snooze_date(snoozed_until)
    self.update(snoozed_until: parse_snooze_date(snoozed_until))
  end

  private

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
    when 'six_months'
      6.month.from_now
    when 'year'
      1.year.from_now
    else
      nil
    end
  end

end