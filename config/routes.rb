# The priority is based upon order of creation: first created -> highest priority.

ActionController::Routing::Routes.draw do |map|
  map.namespace(:argo) do |argo|
    argo.resources :files do |files|
        files.get 'download', :on => :member, :controller => :files, :action => :download
    end
  end
  map.argo 'argo', :controller => :argo, :action => :index

  map.cruise 'cruise/:expocode', :controller => :data_access, :action => :show_cruise
  #map.resources :cruise

  map.feed 'feed/:expocodes', :controller => :data_access, :action => :feed, :format => 'atom'
  
  map.sea_hunt 'sea_hunt', :controller => 'sea_hunt', :action => 'index'
  map.sea_hunt_sort 'sea_hunt_sort', :controller => 'sea_hunt', :action => 'sort_table'

  map.old_submissions 'old_submissions', :controller => 'old_submissions', :action => 'index'
  map.old_submissions_sort 'old_submissions_sort', :controller => 'old_submissions', :action => 'sort_table'

  map.arctic 'arctic', :controller => :by_ocean, :action => :arctic
  map.southern 'southern', :controller => :by_ocean, :action => :southern
  map.indian 'indian', :controller => :by_ocean, :action => :indian

  map.root :controller => :pages, :action => :home

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect '*path', :controller => 'static'
  map.connect '*path', :controller => 'application',
                       :action => 'rescue_404' unless ::ActionController::Base.consider_all_requests_local
end
