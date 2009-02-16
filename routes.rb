resources :instances,  :singular => 'instance', :controller => 'rest/simple/instances'
#connect '/rest/simple/admin/:controller/:action/:id', :controller => Rest::Simple::Admin::EntitiesController
connect '/rest/simple/:controller/:action/:id'
