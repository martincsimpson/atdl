class Project < ApplicationRecord
  belongs_to :workspace, optional: true
  has_many :tasks, dependent: :destroy
  has_many :projects, class_name: "Project", foreign_key: "parent_project_id", dependent: :destroy
  belongs_to :parent_project, class_name: "Project", optional: true

  # Checks to see if we have any tasks in the tree matching the scope
  def any_task_matching?(scope)
    tasks.any? { |task| task.any_task_matching?(scope) } ||
      projects.any? { |sub_project| sub_project.any_task_matching?(scope) }
  end

  # Gets all my tasks that are relevant OR have a relevant subtask
  def tasks_or_subtasks_matching(scope)
    tasks.select { |t| t.matches_scope?(scope) or t.tasks_or_subtasks_matching(scope).any? }
  end

  def parent
    self.parent_project || self.workspace
  end

  def parent_string
    self.parent.parent_string + " - #{self.name}"
  end
end