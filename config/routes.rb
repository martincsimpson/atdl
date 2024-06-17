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
        post :clear_snooze
        get :move_form
        patch :move
      end
    end
  end

  resources :tasks, only: [:show, :edit, :update, :destroy] do
    resources :tasks, only: [:new, :create], as: 'tasks', controller: 'tasks'
    member do
      post :update_status
      post :clear_snooze
      get :move_form
      patch :move
    end
    collection do 
      post :create_inbox_task
      post :bulk_import
    end
  end

  resources :recurring_tasks, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      post 'mark_done'
      post 'mark_failed'
    end
  end

  get 'inbox', to: 'tasks#inbox'
  get 'today', to: 'tasks#today'
  get 'review', to: 'tasks#review'
  get 'master', to: 'tasks#master'
  root 'tasks#master'
end