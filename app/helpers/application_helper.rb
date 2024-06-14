module ApplicationHelper
  def find_root_project(parent)
    return parent if parent.is_a?(Project)
    return find_root_project(parent.project) if parent.is_a?(Task)
  end

  def project_has_tasks?(project, tasks_scope)
    return true if tasks_scope.nil?
    return true if tasks_scope.present? && project.tasks.where(id: tasks_scope.ids).exists?
    
    project.tasks.exists? || project.projects.any? { |sub_project| project_has_tasks?(sub_project, tasks_scope) }
  end

  def task_status_color(status)
    case status
    when 'new'
      'blue'
    when 'todo'
      'orange'
    when 'doing'
      'yellow'
    when 'done'
      'green'
    when 'deferred'
      'purple'
    when 'delegated'
      'red'
    when 'dropped'
      'grey'
    else
      'black'
    end
  end

end

