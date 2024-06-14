# db/seeds.rb

puts "Seeding data..."

# Create Inbox workspace if it doesn't exist
inbox_workspace = Workspace.find_or_create_by(name: 'Inbox')

# Create Inbox project if it doesn't exist
inbox_project = inbox_workspace.projects.find_or_create_by(name: 'Inbox')

puts "Inbox workspace and project created."

puts "Seeding complete."