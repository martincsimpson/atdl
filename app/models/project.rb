class Project < ApplicationRecord
  belongs_to :workspace, optional: true
  has_many :tasks, dependent: :destroy
  has_many :projects, class_name: "Project", foreign_key: "parent_project_id", dependent: :destroy
  belongs_to :parent_project, class_name: "Project", optional: true

  def has_atleast_one_task_for(scope)
    case scope
    when :today
      tasks.due_today.exists? || projects.any? { |sub_project| sub_project.has_atleast_one_task_for(scope) } || tasks.any? { |task| task.has_atleast_one_sub_task_for(scope) }
    when :review
      tasks.for_review.exists? || projects.any? { |sub_project| sub_project.has_atleast_one_task_for(scope) } || tasks.any? { |task| task.has_atleast_one_sub_task_for(scope) }
    else
      false
    end
  end

  def parent
    self.parent_project || self.workspace
  end

  def parent_string
    self.parent.parent_string + " - #{self.name}"
  end
end
