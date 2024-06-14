class Project < ApplicationRecord
  belongs_to :workspace, optional: true
  has_many :tasks, dependent: :destroy
  has_many :projects, class_name: "Project", foreign_key: "parent_project_id", dependent: :destroy
  belongs_to :parent_project, class_name: "Project", optional: true
end
