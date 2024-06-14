Rails.application.routes.draw do
  resources :workspaces do
    resources :projects, only: [:new, :create, :show, :edit, :update, :destroy] do
      resources :projects, only: [:new, :create], as: 'projects', controller: 'projects'
      resources :tasks, only: [:new, :create], controller: 'tasks'
    end
  end

  resources :projects, except: [:index] do
    resources :projects, only: [:new, :create], as: 'projects', controller: 'projects'
    resources :tasks, except: [:index] do
      resources :tasks, only: [:new, :create], as: 'tasks', controller: 'tasks'
      member do
        post :update_status
      end
    end
  end

  resources :tasks, only: [:show, :edit, :update, :destroy] do
    resources :tasks, only: [:new, :create], as: 'tasks', controller: 'tasks'
    member do
      post :update_status
    end
  end

  get 'inbox', to: 'tasks#inbox'
  get 'today', to: 'tasks#today'
  root 'workspaces#index'
end