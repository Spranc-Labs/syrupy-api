Rails.application.routes.draw do
  # Rodauth routes are implicitly defined. You can see them by
  # running `rails rodauth:routes` in your terminal.

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :api do
    # Authentication routes (no auth required)
    resources :auth, only: [] do
      collection do
        post :register
        post :login
        delete :logout
        get :me
        post :refresh
      end
    end

    # Protected API routes (auth required)
    resources :journal_entries do
      member do
        post :analyze
      end
      collection do
        get :insights
        get :ai_service_status
        get :emotion_stats
        get :category_stats
      end
    end
    
    resources :goals do
      member do
        patch :mark_completed
        patch :mark_in_progress
      end
      collection do
        get :due_soon
        get :stats
        get :dashboard
        patch :bulk_update
      end
    end
    
    resources :mood_logs do
      collection do
        get :trends
      end
    end
    
    resources :habits do
      member do
        post :log_completion
        patch :toggle_active
        get :history
      end
      collection do
        get :streaks
        get :stats
        get :dashboard
        post :bulk_log
      end
    end
    
    resources :habit_logs, only: [:index, :show, :create, :update, :destroy]
    
    resources :emotion_logs do
      collection do
        get :stats
        get :trends
        post :quick_log
      end
    end
    
    resources :resources
    
    resources :tags
    
    get "me" => "me#show"
    put "me" => "me#update"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  if Rails.env.development?
    mount GoodJob::Engine, at: "admin/good_job"
    mount PgHero::Engine, at: "admin/pghero"
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end 