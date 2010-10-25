ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  
  
  map.sea_hunt 'sea_hunt', :controller => 'sea_hunt', :action => 'index'
  map.sea_hunt_sort 'sea_hunt_sort', :controller => 'sea_hunt', :action => 'sort_table'

  map.old_submissions 'old_submissions', :controller => 'old_submissions', :action => 'index'
  map.old_submissions_sort 'old_submissions_sort', :controller => 'old_submissions', :action => 'sort_table'

  map.arctic 'arctic', :controller => :by_ocean, :action => :arctic
  map.arctic 'southern', :controller => :by_ocean, :action => :southern
  map.indian 'indian', :controller => :by_ocean, :action => :indian


  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
map.connect '*path', :controller => 'static'
  map.connect '*path', :controller => 'application', :action => 'rescue_404' unless ::ActionController::Base.consider_all_requests_local
end
