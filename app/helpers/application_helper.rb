module ApplicationHelper
  def find_root_project(parent)
    return parent if parent.is_a?(Project)
    return find_root_project(parent.project) if parent.is_a?(Task)
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

