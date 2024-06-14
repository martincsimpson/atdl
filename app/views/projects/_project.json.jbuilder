json.extract! project, :id, :name, :workspace_id, :parent_project_id, :created_at, :updated_at
json.url project_url(project, format: :json)
