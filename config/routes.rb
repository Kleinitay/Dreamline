Dreamline::Application.routes.draw do |map|
  get "authentication/index"
  get "authentication/create"
  get "authentication/destroy"

  resources :users
  resources :videos
  resources :comments
  
  root :to => "application#home"
# ___________________ Videos ______________________________________________________

  # Moozly: to remove - why doesn't work with *page without a page
  match 'video/most_popular'        => 'videos#list', :as => :most_popular_videos, :order=> "most popular", :page => "0"
  match 'video/latest'              => 'videos#list', :as => :latest_videos, :order=> "latest", :page => "0"
  match 'users/:id/videos'          => 'users#videos', :as => :user_videos, :page => "0"
  #------------------------------------------------------------------------------------------------------------------------


  match 'video/latest/*page'        => 'videos#list', :as => :latest_videos, :order=> "latest"#, :requirements => { :page => /(['0'-'9']*)?/}
  match 'video/most_popular/*page'  => 'videos#list', :as => :most_popular_videos, :order=> "most popular" #, :requirements => { :page => /([0-9]*)?/}
  Video::CATEGORIES.values.each do |order|
    # Moozly: to remove - why doesn't work with *page without a page
    match "video/#{order}"          => 'videos#list', :as => :category, :order => "#{order}", :page => "0"
    match "video/#{order}/*page"    => 'videos#list', :as => :category, :order => "#{order}" #, :requirements => { :page => /([0-9]*)?/}
  end

  match 'video/:id'                 => 'videos#show', :as => :video, :requirements => { :id => /([0-9]*)?/ }
  match 'video/:id/edit'            => 'videos#edit', :as => :edit_video, :requirements => { :id => /([0-9]*)?/ }
  match 'video/:id/edit_tags(/new)' => 'videos#edit_tags', :as => :edit_video_tags, :requirements => { :id => /([0-9]*)?/ }
  match 'video/:id/update(/new)'    => "videos#update", :as =>:update_video

# ___________________ FB Videos ______________________________________________________
  match 'fb/new'     => 'fb_videos#new', :as => :fb_video_upload
  match 'fb/create'  => 'fb_videos#create', :as => :fb_video_create
  match 'fb/list'    => 'fb_videos#list', :as => :fb_video_list
  match 'fb/about'   => 'fb_videos#about', :as => :fb_about
  match 'fb/:id/edit_tags(/new)' => 'fb_videos#edit_tags', :as => :fb_edit_video_tags, :requirements => { :id => /([0-9]*)?/ }
  match 'fb/:id/update(/new)'    => "fb_videos#update", :as =>:fb_update_video

#------------------------------------------------------------------------------------------------------------------------

# ___________________ Users ______________________________________________________

  match 'users/:id/videos/*page'  => 'users#videos', :as => :user_videos

    match 'sign_up'     => 'users#new', :as => 'sign_up'
    match 'sign_in'     => 'sessions#new', :as => 'sign_in'
    match 'sign_out'    => 'sessions#destroy', :as => 'destroy'
    match 'auth'        => 'sessions#aoth_athenticate', :as => 'aoth'
    match 'auth_return' => 'sessions#aoth_athenticate_return', :as => 'aoth_return'
    #__________________omniauth paths_______________________________________________
    match 'auth/:provider/callback' => 'authentication#get_uid_and_access_token'
  
# ___________________Clearance routes______________________________________________________
  #Delete later commented lines:
    #resources :passwords,
    #  :controller => 'clearance/passwords',
    #  :only       => [:new, :create]

    #resource  :session,
    #  :controller => 'clearance/sessions',
    #  :only       => [:new, :create, :destroy]

    #resources :users, :controller => 'clearance/users', :only => [:new, :create] do
    #  resource :password,
    #    :controller => 'clearance/passwords',
    #    :only       => [:create, :edit, :update]
    #end
    
    # match 'sign_up'  => 'clearance/users#new', :as => 'sign_up'
    #match 'sign_in'  => 'clearance/sessions#new', :as => 'sign_in'
    #match 'sign_out' => 'clearance/sessions#destroy', :as => 'destroy'

    #resource :session, :controller => 'sessions'
    

    
    
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