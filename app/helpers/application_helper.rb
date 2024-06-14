module ApplicationHelper
  def find_root_project(parent)
    return parent if parent.is_a?(Project)
    return find_root_project(parent.project) if parent.is_a?(Task)
  end
end
