# The priority is based upon order of creation: first created -> highest priority.

ActionController::Routing::Routes.draw do |map|
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  map.search "/search", :controller => "search", :action => "index"
  map.search_advanced "/search/advanced", :controller => "search", :action => "advanced"
  map.search_files "/search/list_files", :controller => "data_access", :action => "list_files"

  # legacy links
  map.groups "/groups", :controller => "legacy", :action => "search"
  map.table "/table", :controller => "legacy", :action => "search"
  map.data_access_list_cruises "/data_access/list_cruises", :controller => "legacy", :action => "data_access_advanced_search"
  map.data_access_advanced_search "/data_access/advanced_search", :controller => "legacy", :action => "data_access_advanced_search"
  map.data_history "/data_history", :controller => "legacy", :action => "data_history"
  map.data_history_full "/data_history/full", :controller => "legacy", :action => "data_history"

  map.namespace(:argo) do |argo|
    argo.resources :files do |files|
        files.get 'download', :on => :member, :controller => :files,
                              :action => :download
    end
  end
  map.argo 'argo', :controller => :argo, :action => :index

  map.datacart "datacart", :controller => "datacart", :action => :index
  map.datacart_add "datacart/add", :controller => "datacart", :action => :add
  map.datacart_remove "datacart/remove", :controller => "datacart", :action => :remove
  map.datacart_add_cruise "datacart/add_cruise", :controller => "datacart", :action => :add_cruise
  map.datacart_remove_cruise "datacart/remove_cruise", :controller => "datacart", :action => :remove_cruise
  map.datacart_add_cruises "datacart/add_cruises", :controller => "datacart", :action => :add_cruises
  map.datacart_remove_cruises "datacart/remove_cruises", :controller => "datacart", :action => :remove_cruises
  map.datacart_clear "datacart/clear", :controller => "datacart", :action => :clear, :conditions => {:method => :post}
  map.datacart_download "datacart/download", :controller => "datacart", :action => :download, :conditions => {:method => :post}

  map.new_submission '/submit', :controller => :submit, :action => :new,
                                :conditions => {:method => :get}
  map.new_simple_submission '/submit/simple', :controller => :submit,
                                              :action => :simple,
                                              :conditions => {:method => :get}
  map.submission '/submit', :controller => :submit, :action => :create,
                        :conditions => {:method => :post}

  map.cruise 'cruise/:expocode', :controller => :data_access, :action => :show_cruise, :conditions => {:method => :get}

  map.cruises 'cruises', :controller => :data_access, :action => :cruises, :conditions => {:method => :get}
  map.cruises_edit 'cruises', :controller => :data_access, :action => :edit_cruise, :conditions => {:method => :post}
  map.contacts 'contacts', :controller => :data_access, :action => :contacts, :conditions => {:method => :get}

  map.feed 'feed/:expocodes', :controller => :data_access, :action => :feed, :format => 'atom'
  
  map.sea_hunt 'sea_hunt', :controller => 'sea_hunt', :action => 'index'
  map.sea_hunt_sort 'sea_hunt_sort', :controller => 'sea_hunt', :action => 'sort_table'

  map.submissions 'submissions', :controller => 'staff/submissions', :action => :index
  map.enqueue 'submissions/enqueue', :controller => 'staff/submissions', :action => :enqueue

  map.queue "queue", :controller => 'staff/queue', :action => :index
  map.queue_csv "queue.:format", :controller => 'staff/queue', :action => :index
  map.queue_new 'queue/new', :controller => 'staff/queue', :action => :new
  map.queue_file_edit 'queue/:id/edit', :controller => 'staff/queue', :action => :queue_edit

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
