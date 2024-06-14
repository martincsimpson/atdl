require 'csv'

# Read the CSV file
csv_file = 'OmniFocus.csv'

# Initialize workspaces
personal_workspace = Workspace.find_or_create_by(name: 'Personal')
bluebik_workspace = Workspace.find_or_create_by(name: 'Bluebik')

# Helper method to find or create projects and tasks
def create_project_or_task(row, workspaces, project_cache)
  type = row['Type']
  name = row['Name']
  flagged = row['Flagged'] == '1'
  task_id = row['Task ID']

  case type
  when 'Project'
    workspace = name.include?('Personal') ? workspaces[:personal] : workspaces[:bluebik]
    project = workspace.projects.find_or_create_by(name: name)
    project_cache[task_id] = project
    puts "Created project: #{project.name} (ID: #{project.id}) in workspace: #{workspace.name}"
  when 'Action'
    parent_id_parts = task_id.split('.')
    parent_id_parts.pop
    parent_id = parent_id_parts.join('.')
    parent = project_cache[parent_id]

    if parent
      if parent.is_a?(Project)
        task = parent.tasks.find_or_create_by(name: name) do |t|
          t.flagged = flagged
        end
      elsif parent.is_a?(Task)
        task = parent.tasks.find_or_create_by(name: name, parent_task: parent) do |t|
          t.flagged = flagged
        end
      end

      project_cache[task_id] = task
      puts "Created task: #{task.name} (ID: #{task.id}) under #{parent.is_a?(Project) ? 'project' : 'task'}: #{parent.name}"
    else
      puts "Error: Could not find parent for task: #{name}"
    end
  else
    puts "Error: Unknown type #{type} for row: #{row.inspect}"
  end
end

# Process the CSV file
workspaces = { personal: personal_workspace, bluebik: bluebik_workspace }
project_cache = {}

CSV.foreach(csv_file, headers: true) do |row|
  create_project_or_task(row, workspaces, project_cache)
rescue StandardError => e
  puts "Error processing row: #{row.inspect}. Error: #{e.message}"
end
