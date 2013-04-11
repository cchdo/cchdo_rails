# The priority is based upon order of creation: first created -> highest priority.

ActionController::Routing::Routes.draw do |map|
  map.namespace(:argo) do |argo|
    argo.resources :files do |files|
        files.get 'download', :on => :member, :controller => :files,
                              :action => :download
    end
  end
  map.argo 'argo', :controller => :argo, :action => :index

  map.bulk "bulk", :controller => "bulk", :action => :index
  map.bulk_add "bulk/add", :controller => "bulk", :action => :add
  map.bulk_remove "bulk/remove", :controller => "bulk", :action => :remove
  map.bulk_clear "bulk/clear", :controller => "bulk", :action => :clear, :conditions => {:method => :post}
  map.bulk_download "bulk/download", :controller => "bulk", :action => :download, :conditions => {:method => :post}

  map.new_submission '/submit', :controller => :submit, :action => :new,
                                :conditions => {:method => :get}
  map.new_simple_submission '/submit/simple', :controller => :submit,
                                              :action => :simple,
                                              :conditions => {:method => :get}
  map.submission '/submit', :controller => :submit, :action => :create,
                        :conditions => {:method => :post}

  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  map.cruise 'cruise/:expocode', :controller => :data_access, :action => :show_cruise
  #map.resources :cruise

  map.feed 'feed/:expocodes', :controller => :data_access, :action => :feed, :format => 'atom'
  
  map.sea_hunt 'sea_hunt', :controller => 'sea_hunt', :action => 'index'
  map.sea_hunt_sort 'sea_hunt_sort', :controller => 'sea_hunt', :action => 'sort_table'

  map.submissions 'submissions', :controller => :staff, :action => :submitted_files

  map.queue "queue", :controller => 'staff/queue', :action => :queue_files
  map.queue_csv "queue.:format", :controller => 'staff/queue', :action => :queue_files
  map.queue_file_edit 'queue/:id/edit', :controller => 'staff/queue', :action => :queue_edit

  map.old_submissions 'old_submissions', :controller => 'old_submissions', :action => 'index'
  map.old_submissions_sort 'old_submissions_sort', :controller => 'old_submissions', :action => 'sort_table'

  map.arctic 'arctic', :controller => :by_ocean, :action => :arctic
  map.southern 'southern', :controller => :by_ocean, :action => :southern
  map.indian 'indian', :controller => :by_ocean, :action => :indian

  map.signin 'signin', :controller => 'staff', :action => 'signin'
  map.signout 'signout', :controller => 'staff', :action => 'signout'

  map.root :controller => :pages, :action => :home

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect '*path', :controller => 'static'
  map.connect '*path', :controller => 'application',
                       :action => 'rescue_404' unless ::ActionController::Base.consider_all_requests_local
end
