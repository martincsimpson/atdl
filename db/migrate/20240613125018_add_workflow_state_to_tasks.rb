class AddWorkflowStateToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :workflow_state, :string
  end
end
