# Include hook code here
require 'ostruct'
::RestSimpleSettings = Madb::parse_settings(File.dirname(__FILE__)+'/config/settings.yml')



AppConfig.plugins.push( {:name => :rest_simple, :admin_entities_view => "/rest/simple/v1/admin/entities/show"  } )
