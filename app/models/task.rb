class Task < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :parent_task, class_name: 'Task', optional: true
  has_many :tasks, class_name: 'Task', foreign_key: 'parent_task_id', dependent: :destroy

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
      event :drop, transitions_to: :dropped
    end
    state :delegated do
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

end