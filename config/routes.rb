Dreamline::Application.routes.draw do |map|
  resources :users
  resources :videos
  resources :comments
  
  root :to => "application#home"
# ___________________ Videos ______________________________________________________

  # Moozly: to remove - why doesn't work with *page without a page
  match 'video/most_popular'        => 'videos#list', :as => :most_popular_videos, :order=> "most popular", :page => "0"
  match 'video/latest'              => 'videos#list', :as => :latest_videos, :order=> "latest", :page => "0"
  match 'user/:id/videos'  => 'users#videos', :as => :user_videos, :page => "0"
  #------------------------------------------------------------------------------------------------------------------------


  match 'video/latest/*page'        => 'videos#list', :as => :latest_videos, :order=> "latest"#, :requirements => { :page => /(['0'-'9']*)?/}
  match 'video/most_popular/*page'  => 'videos#list', :as => :most_popular_videos, :order=> "most popular" #, :requirements => { :page => /([0-9]*)?/}
  Video::CATEGORIES.values.each do |order|
    # Moozly: to remove - why doesn't work with *page without a page
    match "video/#{order}"          => 'videos#list', :as => :category, :order => "#{order}", :page => "0"
    match "video/#{order}/*page"    => 'videos#list', :as => :category, :order => "#{order}" #, :requirements => { :page => /([0-9]*)?/}
  end
  match 'video/:id'                 => 'videos#show', :as => :video, :requirements => { :id => /([0-9]*)?/ }

# ___________________ Users ______________________________________________________

  #match 'user/:id'  => 'users#profile', :as => :user_profile
  match 'user/:id/videos/*page'  => 'users#videos', :as => :user_videos
  

  
# ___________________Clearance routes______________________________________________________
  
    resources :passwords,
      :controller => 'clearance/passwords',
      :only       => [:new, :create]

    resource  :session,
      :controller => 'clearance/sessions',
      :only       => [:new, :create, :destroy]

    resources :users, :controller => 'clearance/users', :only => [:new, :create] do
      resource :password,
        :controller => 'clearance/passwords',
        :only       => [:create, :edit, :update]
    end

    match 'sign_up'  => 'clearance/users#new', :as => 'sign_up'
    match 'sign_in'  => 'clearance/sessions#new', :as => 'sign_in'
    match 'sign_out'  => 'clearance/sessions#destroy', :as => 'sign_out'
    # Why doesn't this work??
    #match 'sign_out' => 'clearance/sessions#destroy', :via => :delete, :as => 'sign_out'
 #____________________________________________________________________________________________
  
  
#____________________________________________________________________________________________
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
 #_____________________________________________________________________________________________________________ 


  
end