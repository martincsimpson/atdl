class Workspace < ApplicationRecord
  has_many :projects, dependent: :destroy

  def any_task_matching?(scope)
    projects.any? { |sub_project| sub_project.any_task_matching?(scope) }
  end

  def parent_string
    self.name
  end

end
