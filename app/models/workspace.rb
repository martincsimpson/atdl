class Workspace < ApplicationRecord
  has_many :projects, dependent: :destroy

  def has_atleast_one_task_for(scope)
    projects.any? { |project| project.has_atleast_one_task_for(scope) }
  end

  def parent_string
    self.name
  end

end
