class Task < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :parent_task, class_name: 'Task', optional: true
  has_many :tasks, class_name: 'Task', foreign_key: 'parent_task_id', dependent: :destroy

  include Workflow

  scope :due_today, -> {
    where('(snoozed_until IS NULL OR snoozed_until <= ?) AND (workflow_state IS NULL OR workflow_state NOT IN (?, ?))', Date.today, 'done', 'dropped')
  }

  scope :for_review, -> {
    where('snoozed_until IS NOT NULL AND snoozed_until > ? AND workflow_state NOT IN (?, ?)', Date.today, 'done', 'dropped')
  }

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
end