class Workspace < ApplicationRecord
  has_many :projects, dependent: :destroy
end
