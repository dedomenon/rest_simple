# Include hook code here
require 'ostruct'
::RestSimpleSettings = OpenStruct.new(
  :list_length => 100
)

AppConfig.plugins.push( {:name => :rest_simple, :admin_entities_view => "/rest/simple/v1/admin/entities/show"  } )
